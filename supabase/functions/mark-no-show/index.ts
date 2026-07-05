// supabase/functions/mark-no-show/index.ts
// Staff taps [Absent] on a booking tile, H+15min after start_time.
import { logActivity } from "../_shared/audit.ts";
import { checkBodySize, handleOptions, jsonResponse } from "../_shared/cors.ts";
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
    if (!(await checkRateLimit(supabase, `mark-no-show:${user.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const { bookingId } = await req.json();
    if (!bookingId) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id, client_id, salon_id, practitioner_id, start_time, status")
      .eq("id", bookingId)
      .single();
    if (bookingError || !booking) return jsonResponse({ error: "booking_not_found" }, 404);

    const { data: staff } = await supabase
      .from("staff_profiles")
      .select("id, user_id")
      .eq("user_id", user.id)
      .maybeSingle();

    const isOwnerOrManager = user.role === "owner" || user.role === "manager";
    const isOwnPractitioner = staff?.id === booking.practitioner_id;
    if (!isOwnerOrManager && !isOwnPractitioner) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const gracePassed = Date.now() >= new Date(booking.start_time).getTime() + 15 * 60000;
    if (!gracePassed) {
      return jsonResponse(
        { error: "grace_period_not_elapsed", message: "Disponible 15 min après le début du RDV." },
        409,
      );
    }

    await supabase.from("bookings").update({
      status: "no_show",
      no_show_at: new Date().toISOString(),
    }).eq("id", bookingId);

    // Best-effort — a missed workflow firing must never fail the no-show.
    supabase.functions.invoke("execute-workflow", {
      body: {
        trigger_type: "booking.no_show",
        salon_id: booking.salon_id,
        context: { booking_id: booking.id, client_id: booking.client_id },
      },
    }).catch(() => {});

    const { data: client } = await supabase
      .from("users")
      .select("reliability_score")
      .eq("id", booking.client_id)
      .single();

    const newScore = Math.max(0, (client?.reliability_score ?? 100) - 1);
    await supabase.from("users").update({ reliability_score: newScore }).eq("id", booking.client_id);

    const { count } = await supabase
      .from("bookings")
      .select("id", { count: "exact", head: true })
      .eq("client_id", booking.client_id)
      .eq("status", "no_show");

    if ((count ?? 0) >= 3) {
      await logActivity(supabase, req, {
        salonId: booking.salon_id,
        userId: user.id,
        typeAction: "booking_no_show",
        newValues: { clientId: booking.client_id, noShowCount: count },
      });
    }

    return jsonResponse({ status: "no_show", reliabilityScore: newScore }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "mark_no_show_failed", message }, 500);
  }
});
