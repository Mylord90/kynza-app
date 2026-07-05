// supabase/functions/proxipay-create-session/index.ts
// Staff-initiated: creates a short-lived proxipay_sessions row so an
// in-person client can scan it and pay without staff ever touching the
// client's Mobile Money number. Amount is always read from the booking
// server-side — never trusted from the request body (R02/R16).
import { checkBodySize, handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

const STAFF_ROLES = ["owner", "manager", "staff"];

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const tooLarge = checkBodySize(req);
  if (tooLarge) return tooLarge;

  try {
    const user = await getAuthenticatedUser(req);
    if (!STAFF_ROLES.includes(user.role) || !user.salon_id) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const supabase = createServiceRoleClient();
    if (
      !(await checkRateLimit(supabase, `proxipay-create-session:${user.id}`, 30, 60))
    ) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const { bookingId } = await req.json();
    if (!bookingId) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id, salon_id, amount_bif, status")
      .eq("id", bookingId)
      .is("deleted_at", null)
      .single();

    if (bookingError || !booking) return jsonResponse({ error: "booking_not_found" }, 404);
    if (booking.salon_id !== user.salon_id) return jsonResponse({ error: "forbidden" }, 403);
    if (booking.status !== "confirmed") {
      return jsonResponse({ error: "booking_not_collectible" }, 409);
    }

    const { data: session, error: sessionError } = await supabase
      .from("proxipay_sessions")
      .insert({
        booking_id: booking.id,
        salon_id: booking.salon_id,
        staff_id: user.id,
        amount_bif: booking.amount_bif,
      })
      .select("id, amount_bif, expires_at")
      .single();

    if (sessionError || !session) {
      return jsonResponse({ error: "session_create_failed" }, 500);
    }

    return jsonResponse(
      {
        sessionId: session.id,
        amountBif: session.amount_bif,
        expiresAt: session.expires_at,
      },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "proxipay_create_session_failed", message }, 500);
  }
});
