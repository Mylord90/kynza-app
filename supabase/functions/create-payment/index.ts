// supabase/functions/create-payment/index.ts
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { buildIdempotencyKey } from "../_shared/hmac.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

const LEAPA_API_KEY = Deno.env.get("LEAPA_API_KEY");
const LEAPA_BASE_URL = Deno.env.get("LEAPA_BASE_URL") ?? "https://api.leapa.bi/v1";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const user = await getAuthenticatedUser(req);
    const { bookingId, method, phone } = await req.json();
    if (!bookingId || !method) return jsonResponse({ error: "missing_fields" }, 400);

    const supabase = createServiceRoleClient();

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

    if (!LEAPA_API_KEY) {
      // No sandbox/production credentials configured in this environment —
      // mark as processing so the Flutter polling UI still behaves
      // correctly; a real deployment must set LEAPA_API_KEY.
      await supabase.from("transactions").update({ status: "processing" }).eq(
        "idempotency_key",
        idempotencyKey,
      );
      return jsonResponse({ idempotencyKey, status: "processing", sandbox: true }, 200);
    }

    const leapaRes = await fetch(`${LEAPA_BASE_URL}/payments/initiate`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LEAPA_API_KEY}`,
        "Idempotency-Key": idempotencyKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: booking.amount_bif,
        currency: "BIF",
        method,
        phone,
        reference: idempotencyKey,
      }),
    });

    if (!leapaRes.ok) {
      await supabase.from("transactions").update({ status: "failed" }).eq(
        "idempotency_key",
        idempotencyKey,
      );
      return jsonResponse({ error: "leapa_initiation_failed" }, 502);
    }

    const leapaData = await leapaRes.json();
    await supabase
      .from("transactions")
      .update({ status: "processing", leapa_reference: leapaData.reference ?? null })
      .eq("idempotency_key", idempotencyKey);

    return jsonResponse({ idempotencyKey, status: "processing" }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_payment_failed", message }, 500);
  }
});
