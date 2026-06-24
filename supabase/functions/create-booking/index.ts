// supabase/functions/create-booking/index.ts
// Atomic booking creation — relies on the DB-level UNIQUE(practitioner_id,
// start_time) constraint (kynza-booking-engine.md §2) for the race-condition
// guard rather than an explicit SELECT FOR UPDATE, since a single INSERT
// already serializes correctly against that constraint in Postgres; this
// avoids holding a row lock across a slower multi-step transaction.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

const BUJUMBURA_OFFSET_MS = 2 * 3600_000; // Africa/Bujumbura, UTC+2, no DST

// Bujumbura-local calendar date ("YYYY-MM-DD") and day_of_week (0=Mon..6=Sun,
// matching every day_of_week column in this schema) for an absolute instant —
// never the server's own UTC date, which can be off by one near midnight.
function bujumburaDateParts(instant: Date): { dateStr: string; dayOfWeek: number } {
  const shifted = new Date(instant.getTime() + BUJUMBURA_OFFSET_MS);
  const dateStr = shifted.toISOString().substring(0, 10);
  const dayOfWeek = (shifted.getUTCDay() + 6) % 7;
  return { dateStr, dayOfWeek };
}

// Module 3.I — defense-in-depth checks beyond the UNIQUE(practitioner_id,
// start_time) race-condition guard already enforced at INSERT time: a slot
// the client-side picker considered free can still have been closed via an
// exception or recurring break between page load and submission.
async function checkAdvancedAvailability(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  salonId: string,
  practitionerId: string,
  start: Date,
  end: Date,
): Promise<string | null> {
  const { dateStr, dayOfWeek } = bujumburaDateParts(start);

  const { data: exceptions } = await supabase
    .from("availability_exceptions")
    .select("staff_id, is_closed")
    .eq("salon_id", salonId)
    .lte("start_date", dateStr)
    .gte("end_date", dateStr)
    .is("deleted_at", null)
    .or(`staff_id.eq.${practitionerId},staff_id.is.null`);

  const blocking = (exceptions ?? []).find(
    (e: { staff_id: string | null; is_closed: boolean }) => e.is_closed,
  );
  if (blocking) {
    return "Ce salon ou ce praticien est indisponible à cette date.";
  }

  const { data: breaks } = await supabase
    .from("staff_breaks")
    .select("start_time, end_time")
    .eq("staff_id", practitionerId)
    .eq("day_of_week", dayOfWeek)
    .is("deleted_at", null);

  // Bujumbura wall-clock minutes-since-midnight for start/end, comparable
  // with the HH:MM:SS TIME columns below (also Bujumbura wall-clock).
  const shiftedStart = new Date(start.getTime() + BUJUMBURA_OFFSET_MS);
  const shiftedEnd = new Date(end.getTime() + BUJUMBURA_OFFSET_MS);
  const startMinutes = shiftedStart.getUTCHours() * 60 + shiftedStart.getUTCMinutes();
  const endMinutes = shiftedEnd.getUTCHours() * 60 + shiftedEnd.getUTCMinutes();
  for (const b of breaks ?? []) {
    const [bStartH, bStartM] = (b.start_time as string).split(":").map(Number);
    const [bEndH, bEndM] = (b.end_time as string).split(":").map(Number);
    const bStart = bStartH * 60 + bStartM;
    const bEnd = bEndH * 60 + bEndM;
    if (startMinutes < bEnd && endMinutes > bStart) {
      return "Ce créneau tombe pendant une pause du praticien.";
    }
  }

  return null;
}

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

    const availabilityError = await checkAdvancedAvailability(
      supabase,
      salonId,
      practitionerId,
      start,
      end,
    );
    if (availabilityError) {
      return jsonResponse({ error: "slot_unavailable", message: availabilityError }, 409);
    }

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

    // Best-effort — never blocks the booking response on a notification
    // failure (kynza-notifications-whatsapp.md §1).
    supabase.functions.invoke("send-notification", {
      body: { bookingId: booking.id, event: "booking_created" },
    }).catch(() => {});

    return jsonResponse({ booking }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_booking_failed", message }, 500);
  }
});
