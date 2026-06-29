// supabase/functions/leapa-webhook/index.ts
// Called by Leapa, never by the Flutter app. No JWT auth — HMAC signature
// is the only trust boundary, so it MUST be verified before any mutation.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { verifyLeapaSignature } from "../_shared/hmac.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

const LEAPA_WEBHOOK_SECRET = Deno.env.get("LEAPA_WEBHOOK_SECRET") ?? "";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const rawBody = await req.text();
  const signature = req.headers.get("x-leapa-signature") ?? "";

  if (!LEAPA_WEBHOOK_SECRET || !verifyLeapaSignature(rawBody, signature, LEAPA_WEBHOOK_SECRET)) {
    return jsonResponse({ error: "invalid_signature" }, 401);
  }

  const payload = JSON.parse(rawBody);
  const { idempotency_key, status, leapa_reference, leapa_transaction_id } = payload;
  if (!idempotency_key || !status) return jsonResponse({ error: "malformed_payload" }, 400);

  const supabase = createServiceRoleClient();

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
      .update({ status: "confirmed", payment_status: "completed", payment_method: payload.method ?? null })
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

    await supabase.functions.invoke("send-notification", {
      body: { bookingId: existing.booking_id, event: "booking_confirmed" },
    });

    // Best-effort — a missed workflow firing must never fail the webhook.
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
});
