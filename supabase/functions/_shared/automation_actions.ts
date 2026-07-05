// supabase/functions/_shared/automation_actions.ts
// Shared by execute-workflow (runs delay_seconds=0 actions inline) and
// run-scheduled-actions (cron-driven runner for delayed/retried actions)
// — one implementation, never duplicated between the two call sites.
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { logActivity } from "./audit.ts";

export interface ActionResult {
  status: "success" | "failed" | "skipped";
  error?: string;
}

interface ActionRow {
  action_type: string;
  params: Record<string, unknown>;
}

const MAX_ATTEMPTS = 3;
// Exponential backoff in minutes after a failed attempt: 2, 4, 8.
const BACKOFF_MINUTES = [2, 4, 8];

/**
 * Records the outcome of one action attempt on its automation_action_runs
 * row, applying the same retry-with-backoff policy regardless of whether
 * the attempt ran inline (execute-workflow, delay_seconds=0) or via the
 * cron queue (run-scheduled-actions) — an action that fails on its first
 * *inline* attempt must still get retried, not be marked terminally
 * failed just because it happened to run synchronously.
 */
export async function recordActionRunResult(
  admin: SupabaseClient,
  runId: string,
  attemptCount: number,
  result: ActionResult,
): Promise<"success" | "failed" | "skipped" | "pending"> {
  if (result.status !== "failed") {
    await admin.from("automation_action_runs").update({
      status: result.status,
      attempt_count: attemptCount,
      last_error: result.error ?? null,
      executed_at: new Date().toISOString(),
    }).eq("id", runId);
    return result.status;
  }

  if (attemptCount >= MAX_ATTEMPTS) {
    await admin.from("automation_action_runs").update({
      status: "failed",
      attempt_count: attemptCount,
      last_error: result.error ?? "action_failed",
      executed_at: new Date().toISOString(),
    }).eq("id", runId);
    return "failed";
  }

  const backoffMinutes = BACKOFF_MINUTES[attemptCount - 1] ?? 8;
  await admin.from("automation_action_runs").update({
    // CP0: explicitly back to 'pending' — the row was claimed into
    // 'processing' by claim_pending_action_runs() before this ran, and
    // must be reselectable once its backoff window passes.
    status: "pending",
    attempt_count: attemptCount,
    last_error: result.error ?? "action_failed",
    scheduled_at: new Date(Date.now() + backoffMinutes * 60_000).toISOString(),
  }).eq("id", runId);
  return "pending";
}

const UNIMPLEMENTED_ACTION_TYPES = new Set([
  "update_stats",
  "send_email",
  "create_invoice",
]);

export async function runAction(
  admin: SupabaseClient,
  action: ActionRow,
  context: Record<string, unknown>,
  salonId: string,
): Promise<ActionResult> {
  if (UNIMPLEMENTED_ACTION_TYPES.has(action.action_type)) {
    return { status: "skipped", error: "not_implemented_this_phase" };
  }

  switch (action.action_type) {
    case "send_notification":
    case "send_whatsapp":
      return await sendNotification(admin, action.params, context, salonId);
    case "stamp_loyalty":
      return await stampLoyalty(admin, context, salonId);
    case "add_loyalty_bonus":
      return await addLoyaltyBonus(admin, action.params, context, salonId);
    case "log_activity":
      return await logActivityAction(admin, action.params, context, salonId);
    default:
      return { status: "failed", error: `unknown_action_type:${action.action_type}` };
  }
}

async function sendNotification(
  admin: SupabaseClient,
  params: Record<string, unknown>,
  context: Record<string, unknown>,
  salonId: string,
): Promise<ActionResult> {
  const event = params.event as string | undefined;
  const target = (params.target as string | undefined) ?? "client";
  if (!event) return { status: "failed", error: "missing_event_param" };

  const body: Record<string, unknown> = { event, salonId };

  if (target === "client") {
    if (context.booking_id) body.bookingId = context.booking_id;
    else if (context.client_id) body.userId = context.client_id;
    else return { status: "failed", error: "no_client_in_context" };
  } else if (target === "owner") {
    const { data: salon } = await admin
      .from("salons")
      .select("owner_id")
      .eq("id", salonId)
      .single();
    if (!salon?.owner_id) return { status: "failed", error: "salon_owner_not_found" };
    body.userId = salon.owner_id;
    if (context.booking_id) {
      body.relatedBookingId = context.booking_id;
      const { data: booking } = await admin
        .from("bookings")
        .select("users:client_id(full_name)")
        .eq("id", context.booking_id as string)
        .single();
      const clientName =
        (booking?.users as { full_name?: string } | null)?.full_name ?? "Un client";
      body.data = { client_name: clientName };
    }
  } else if (target === "staff") {
    const staffUserId = context.staff_user_id ?? context.practitioner_user_id;
    if (!staffUserId) return { status: "failed", error: "no_staff_in_context" };
    body.userId = staffUserId;
    if (context.booking_id) body.relatedBookingId = context.booking_id;
  } else {
    return { status: "failed", error: `unknown_target:${target}` };
  }

  const { error } = await admin.functions.invoke("send-notification", { body });
  if (error) return { status: "failed", error: error.message ?? "send_notification_failed" };
  return { status: "success" };
}

async function stampLoyalty(
  admin: SupabaseClient,
  context: Record<string, unknown>,
  salonId: string,
): Promise<ActionResult> {
  const clientId = context.client_id as string | undefined;
  if (!clientId) return { status: "failed", error: "no_client_in_context" };

  const { data: card } = await admin
    .from("loyalty_cards")
    .select("id")
    .eq("salon_id", salonId)
    .eq("client_id", clientId)
    .maybeSingle();
  if (!card) return { status: "failed", error: "loyalty_card_not_found" };

  const { data: updated, error } = await admin.rpc("add_loyalty_stamp", {
    p_card_id: card.id,
    p_booking_id: context.booking_id ?? null,
  });
  if (error) return { status: "failed", error: error.message };

  const { data: program } = await admin
    .from("loyalty_programs")
    .select("stamps_required")
    .eq("salon_id", salonId)
    .maybeSingle();

  if (program && updated.stamps_count >= program.stamps_required) {
    // Best-effort — a missed "card full" trigger must never fail the
    // stamp itself, which has already succeeded.
    admin.functions.invoke("execute-workflow", {
      body: {
        trigger_type: "loyalty.card_full",
        salon_id: salonId,
        context: { card_id: card.id, client_id: clientId },
      },
    }).catch(() => {});
  }

  return { status: "success" };
}

async function addLoyaltyBonus(
  admin: SupabaseClient,
  params: Record<string, unknown>,
  context: Record<string, unknown>,
  salonId: string,
): Promise<ActionResult> {
  const clientId = context.client_id as string | undefined;
  if (!clientId) return { status: "failed", error: "no_client_in_context" };

  const stamps = Number(params.stamps ?? 1);
  if (!Number.isFinite(stamps) || stamps <= 0) {
    return { status: "failed", error: "invalid_stamps_param" };
  }

  const { data: card } = await admin
    .from("loyalty_cards")
    .select("id")
    .eq("salon_id", salonId)
    .eq("client_id", clientId)
    .maybeSingle();
  if (!card) return { status: "failed", error: "loyalty_card_not_found" };

  const { error } = await admin.rpc("add_loyalty_bonus_stamps", {
    p_card_id: card.id,
    p_stamps: stamps,
    p_reason: params.reason ?? null,
  });
  if (error) return { status: "failed", error: error.message };
  return { status: "success" };
}

async function logActivityAction(
  admin: SupabaseClient,
  params: Record<string, unknown>,
  context: Record<string, unknown>,
  salonId: string,
): Promise<ActionResult> {
  const { data: salon } = await admin
    .from("salons")
    .select("owner_id")
    .eq("id", salonId)
    .single();
  if (!salon?.owner_id) return { status: "failed", error: "salon_owner_not_found" };

  await logActivity(admin, {
    salonId,
    userId: salon.owner_id,
    typeAction: (params.action as string | undefined) ?? "workflow_action",
    newValues: context,
  });
  return { status: "success" };
}