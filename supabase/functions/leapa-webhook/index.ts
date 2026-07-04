// supabase/functions/leapa-webhook/index.ts
// Called by Leapa, never by the Flutter app. No JWT auth — HMAC signature
// is the only trust boundary, so it MUST be verified before any mutation.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { verifyLeapaSignature } from "../_shared/hmac.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

const LEAPA_WEBHOOK_SECRET = Deno.env.get("LEAPA_WEBHOOK_SECRET") ?? "";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-leapa-signature") ?? "";

    if (!LEAPA_WEBHOOK_SECRET || !verifyLeapaSignature(rawBody, signature, LEAPA_WEBHOOK_SECRET)) {
      return jsonResponse({ error: "invalid_signature" }, 401);
    }

    const supabase = createServiceRoleClient();

    // No JWT/caller identity exists on this externally-reachable webhook, so
    // this is a single global bucket rather than per-caller — checked only
    // after signature verification, so an attacker without the HMAC secret
    // can't burn Leapa's own legitimate rate budget by spamming invalid
    // requests. 120/60s comfortably covers real webhook + retry traffic
    // while still bounding a flapping/misbehaving sender.
    if (!(await checkRateLimit(supabase, "leapa-webhook:global", 120, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return jsonResponse({ error: "malformed_payload" }, 400);
    }
    const { idempotency_key, status, leapa_reference, leapa_transaction_id } = payload as {
      idempotency_key?: string;
      status?: string;
      leapa_reference?: string;
      leapa_transaction_id?: string;
      method?: string;
    };
    if (!idempotency_key || !status) return jsonResponse({ error: "malformed_payload" }, 400);

    const { data: existing } = await supabase
      .from("transactions")
      .select("status, booking_id, salon_id")
      .eq("idempotency_key", idempotency_key)
      .single();

    if (!existing) return jsonResponse({ error: "transaction_not_found" }, 404);
    if (existing.status === "completed") {
      return jsonResponse({ message: "already_processed" }, 200); // idempotent
    }

    await supabase
      .from("transactions")
      .update({
        status,
        leapa_reference: leapa_reference ?? null,
        leapa_transaction_id: leapa_transaction_id ?? null,
        confirmed_at: status === "completed" ? new Date().toISOString() : null,
      })
      .eq("idempotency_key", idempotency_key);

    if (status === "completed") {
      await supabase
        .from("bookings")
        .update({
          status: "confirmed",
          payment_status: "completed",
          payment_method: (payload as { method?: string }).method ?? null,
        })
        .eq("id", existing.booking_id);

      const { data: confirmedBooking } = await supabase
        .from("bookings")
        .select("client_id")
        .eq("id", existing.booking_id)
        .single();

      await supabase.from("activity_logs").insert({
        salon_id: existing.salon_id,
        user_id: confirmedBooking?.client_id,
        type_action: "payment_completed",
        new_values: { bookingId: existing.booking_id, idempotency_key },
      });

      // Best-effort — a missed notification/workflow firing must never fail the webhook
      // (Leapa retries on any non-2xx, which would otherwise cause duplicate processing).
      supabase.functions.invoke("send-notification", {
        body: { bookingId: existing.booking_id, event: "booking_confirmed" },
      }).catch(() => {});

      supabase.functions.invoke("execute-workflow", {
        body: {
          trigger_type: "booking.confirmed",
          salon_id: existing.salon_id,
          context: { booking_id: existing.booking_id, client_id: confirmedBooking?.client_id },
        },
      }).catch(() => {});
    } else if (status === "failed" || status === "expired") {
      await supabase
        .from("bookings")
        .update({ payment_status: status })
        .eq("id", existing.booking_id);
    }

    return jsonResponse({ status: "ok" }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    return jsonResponse({ error: "leapa_webhook_failed", message }, 500);
  }
});
