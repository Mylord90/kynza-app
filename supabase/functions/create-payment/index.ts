// supabase/functions/create-payment/index.ts
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
    const user = await getAuthenticatedUser(req);
    const supabase = createServiceRoleClient();
    if (!(await checkRateLimit(supabase, `create-payment:${user.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const { bookingId, method, phone } = await req.json();
    if (!bookingId || !method) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id, salon_id, client_id, amount_bif, status")
      .eq("id", bookingId)
      .is("deleted_at", null)
      .single();

    if (bookingError || !booking) return jsonResponse({ error: "booking_not_found" }, 404);
    if (booking.client_id !== user.id) return jsonResponse({ error: "forbidden" }, 403);
    if (booking.status !== "pending_payment") {
      return jsonResponse({ error: "booking_not_payable" }, 409);
    }

    const idempotencyKey = buildIdempotencyKey(bookingId);

    const { error: txError } = await supabase.from("transactions").insert({
      salon_id: booking.salon_id,
      booking_id: booking.id,
      amount_bif: booking.amount_bif,
      method,
      status: "pending",
      idempotency_key: idempotencyKey,
    });

    if (txError) {
      // UNIQUE violation = a request for this booking/minute is already
      // in flight — return the existing state instead of a second Leapa call.
      return jsonResponse({ idempotencyKey, alreadyPending: true }, 200);
    }

    const result = await initiateLeapaPayment({
      supabase,
      idempotencyKey,
      amountBif: booking.amount_bif,
      method,
      phone,
    });

    if (result.status === "failed") {
      return jsonResponse({ error: "leapa_initiation_failed" }, 502);
    }

    return jsonResponse(
      { idempotencyKey, status: result.status, sandbox: result.sandbox },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_payment_failed", message }, 500);
  }
});
