// supabase/functions/calculate-commission/index.ts
// Called from BookingActionNotifier.markCompleted right after the booking
// is marked completed (same best-effort, non-blocking shape as
// _awardLoyaltyStamp in booking_providers.dart) — computes the staff
// member's commission for this booking from their staff_profiles rate.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `calculate-commission:${caller.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = await req.json();
    const bookingId = body.booking_id ?? body.bookingId;
    if (!bookingId) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: booking, error: bookingError } = await admin
      .from("bookings")
      .select("id, salon_id, practitioner_id, amount_bif, status")
      .eq("id", bookingId)
      .maybeSingle();
    if (bookingError) throw bookingError;
    if (!booking || booking.status !== "completed") {
      return jsonResponse({ error: "booking_not_completed" }, 400);
    }
    // CP2 finding (docs/certification-v2/CP2_DEEP_SECURITY.md): this function had no ownership
    // check at all, letting any authenticated user learn another salon's booking amount and
    // commission by supplying an arbitrary booking_id. caller.salon_id comes from the users
    // table (immutable via client API, see protect_user_columns), so this can't be spoofed.
    if (caller.salon_id !== booking.salon_id) {
      return jsonResponse({ error: "forbidden" }, 403);
    }
    if (!booking.practitioner_id) {
      return jsonResponse({ success: true, skipped: "no_practitioner" }, 200);
    }

    const { data: staff, error: staffError } = await admin
      .from("staff_profiles")
      .select("commission_type, commission_rate")
      .eq("id", booking.practitioner_id)
      .maybeSingle();
    if (staffError) throw staffError;
    if (!staff || Number(staff.commission_rate) <= 0) {
      return jsonResponse({ success: true, skipped: "no_commission_rate" }, 200);
    }

    const rateValue = Number(staff.commission_rate);
    const amountBif = staff.commission_type === "percent"
      ? Math.round((booking.amount_bif * rateValue) / 100)
      : Math.round(rateValue);

    const { error: insertError } = await admin.from("staff_commissions").insert({
      staff_id: booking.practitioner_id,
      salon_id: booking.salon_id,
      booking_id: booking.id,
      rate_type: staff.commission_type,
      rate_value: rateValue,
      amount_bif: amountBif,
    });
    if (insertError) {
      // booking_id is UNIQUE — a retried call hitting this twice is not
      // an error, the commission already exists.
      if (insertError.code === "23505") {
        return jsonResponse({ success: true, skipped: "already_calculated" }, 200);
      }
      throw insertError;
    }

    await admin.from("activity_logs").insert({
      salon_id: booking.salon_id,
      user_id: caller.id,
      type_action: "commission_calculated",
      new_values: { bookingId: booking.id, staffId: booking.practitioner_id, amountBif },
    });

    return jsonResponse({ success: true, amountBif }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "calculate_commission_failed", message }, 500);
  }
});