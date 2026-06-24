// supabase/functions/create-booking/index.ts
// Atomic booking creation — relies on the DB-level UNIQUE(practitioner_id,
// start_time) constraint (kynza-booking-engine.md §2) for the race-condition
// guard rather than an explicit SELECT FOR UPDATE, since a single INSERT
// already serializes correctly against that constraint in Postgres; this
// avoids holding a row lock across a slower multi-step transaction.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const user = await getAuthenticatedUser(req);
    const body = await req.json();
    const { salonId, serviceId, practitionerId, startTime, notes } = body;

    if (!salonId || !serviceId || !practitionerId || !startTime) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }

    const supabase = createServiceRoleClient();

    const { data: salon } = await supabase
      .from("salons")
      .select("plan, monthly_bookings_count")
      .eq("id", salonId)
      .single();

    if (salon?.plan === "free" && (salon.monthly_bookings_count ?? 0) >= 20) {
      return jsonResponse(
        { error: "freemium_limit_reached", message: "Limite atteinte. Vos clients attendent." },
        403,
      );
    }

    const { data: service, error: serviceError } = await supabase
      .from("services")
      .select("salon_id, duration_min, buffer_min, price_bif, is_active")
      .eq("id", serviceId)
      .is("deleted_at", null)
      .single();

    if (serviceError || !service || service.salon_id !== salonId || !service.is_active) {
      return jsonResponse({ error: "service_not_found" }, 404);
    }

    const start = new Date(startTime);
    if (start.getTime() < Date.now()) {
      return jsonResponse({ error: "slot_in_past", message: "Ce créneau est déjà passé." }, 400);
    }
    const end = new Date(start.getTime() + service.duration_min * 60000);
    const bufferEnd = new Date(end.getTime() + service.buffer_min * 60000);

    const { data: booking, error: insertError } = await supabase
      .from("bookings")
      .insert({
        salon_id: salonId,
        client_id: user.id,
        practitioner_id: practitionerId,
        service_id: serviceId,
        start_time: start.toISOString(),
        end_time: end.toISOString(),
        buffer_end_time: bufferEnd.toISOString(),
        amount_bif: service.price_bif,
        notes: notes ?? null,
        status: "pending_payment",
      })
      .select()
      .single();

    if (insertError) {
      if (insertError.code === "23505") {
        const { data: alternatives } = await supabase
          .from("bookings")
          .select("start_time")
          .eq("practitioner_id", practitionerId)
          .gte("start_time", start.toISOString())
          .lt("start_time", new Date(start.getTime() + 24 * 3600000).toISOString());
        return jsonResponse(
          {
            error: "slot_taken",
            message: "Ce créneau vient d'être réservé. Voici les prochains disponibles.",
            alternatives: alternatives ?? [],
          },
          409,
        );
      }
      throw insertError;
    }

    await supabase.from("activity_logs").insert({
      salon_id: salonId,
      user_id: user.id,
      type_action: "booking_created",
      new_values: { bookingId: booking.id },
    });

    return jsonResponse({ booking }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_booking_failed", message }, 500);
  }
});
