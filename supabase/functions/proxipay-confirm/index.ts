// supabase/functions/proxipay-confirm/index.ts
// Client-initiated: called after the client scans the staff's ProxiPay QR
// and enters their own Mobile Money number. The phone number is only ever
// forwarded to Leapa (via initiateLeapaPayment) — it is never persisted on
// proxipay_sessions or seen by the staff device. Reuses the exact
// idempotency-key/transactions flow create-payment already uses, so
// settlement still arrives through the existing leapa-webhook.
import { logAppCheckStatus } from "../_shared/app_check.ts";
import { checkBodySize, handleOptions, jsonResponse } from "../_shared/cors.ts";
import { buildIdempotencyKey } from "../_shared/hmac.ts";
import { initiateLeapaPayment } from "../_shared/leapa.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const tooLarge = checkBodySize(req);
  if (tooLarge) return tooLarge;

  try {
    logAppCheckStatus(req, "proxipay-confirm");
    const user = await getAuthenticatedUser(req);
    const supabase = createServiceRoleClient();
    if (!(await checkRateLimit(supabase, `proxipay-confirm:${user.id}`, 20, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const { sessionId, method, phone } = await req.json();
    if (!sessionId || !method || !phone) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: session, error: sessionError } = await supabase
      .from("proxipay_sessions")
      .select("id, booking_id, salon_id, amount_bif, status, expires_at")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) return jsonResponse({ error: "session_not_found" }, 404);
    if (session.status === "confirmed") {
      // Idempotent re-tap (e.g. client double-submits) — not an error.
      return jsonResponse({ sessionId, alreadyConfirmed: true }, 200);
    }
    if (session.status !== "pending" || new Date(session.expires_at) <= new Date()) {
      return jsonResponse({ error: "session_expired" }, 410);
    }

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id, status")
      .eq("id", session.booking_id)
      .single();

    if (bookingError || !booking || booking.status !== "confirmed") {
      return jsonResponse({ error: "booking_not_collectible" }, 409);
    }

    const idempotencyKey = buildIdempotencyKey(session.booking_id);

    const { error: txError } = await supabase.from("transactions").insert({
      salon_id: session.salon_id,
      booking_id: session.booking_id,
      amount_bif: session.amount_bif,
      method,
      status: "pending",
      idempotency_key: idempotencyKey,
    });

    if (txError) {
      // A request for this booking/minute is already in flight — mirror
      // create-payment's idempotent response instead of a second Leapa call.
      return jsonResponse({ sessionId, idempotencyKey, alreadyPending: true }, 200);
    }

    const result = await initiateLeapaPayment({
      supabase,
      idempotencyKey,
      amountBif: session.amount_bif,
      method,
      phone,
    });

    if (result.status === "failed") {
      return jsonResponse({ error: "leapa_initiation_failed" }, 502);
    }

    await supabase
      .from("proxipay_sessions")
      .update({
        status: "confirmed",
        client_id: user.id,
        confirmed_at: new Date().toISOString(),
      })
      .eq("id", sessionId);

    return jsonResponse({ sessionId, idempotencyKey, status: result.status }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "proxipay_confirm_failed", message }, 500);
  }
});
