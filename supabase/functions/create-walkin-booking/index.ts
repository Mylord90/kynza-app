// supabase/functions/create-walkin-booking/index.ts
// Owner Dashboard "+ Nouveau RDV" FAB — the client has no KYNZA account.
// Reuses an existing guest/registered client by phone if one already
// exists, otherwise provisions a minimal guest auth.users + public.users
// row (service_role only — never reachable from the authenticated client
// directly, since creating an auth identity is a privileged operation).
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    const body = await req.json();
    const { salonId, serviceId, practitionerId, startTime, guestFirstName, guestPhone, notes } =
      body;

    if (
      !salonId || !serviceId || !practitionerId || !startTime || !guestFirstName || !guestPhone
    ) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }
    if (caller.salon_id !== salonId || !["owner", "manager"].includes(caller.role)) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const supabase = createServiceRoleClient();
    const phone = guestPhone.trim();

    let clientId: string;
    const { data: existing } = await supabase
      .from("users")
      .select("id")
      .eq("phone", phone)
      .is("deleted_at", null)
      .maybeSingle();

    if (existing) {
      clientId = existing.id;
    } else {
      const { data: created, error: createError } = await supabase.auth.admin.createUser({
        phone,
        phone_confirm: true,
        password: crypto.randomUUID(),
        user_metadata: { full_name: guestFirstName },
      });
      if (createError || !created.user) {
        return jsonResponse(
          { error: "guest_creation_failed", message: createError?.message },
          500,
        );
      }
      clientId = created.user.id;

      // handle_new_user() already inserted a default public.users row from
      // the auth.users trigger — service_role bypasses protect_user_columns
      // to finish provisioning it as a guest client in one step.
      await supabase
        .from("users")
        .update({
          full_name: guestFirstName,
          first_name: guestFirstName,
          phone,
          role: "client",
          profile_completed: true,
          is_guest: true,
        })
        .eq("id", clientId);
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
    const end = new Date(start.getTime() + service.duration_min * 60000);
    const bufferEnd = new Date(end.getTime() + service.buffer_min * 60000);

    const { data: booking, error: insertError } = await supabase
      .from("bookings")
      .insert({
        salon_id: salonId,
        client_id: clientId,
        practitioner_id: practitionerId,
        service_id: serviceId,
        start_time: start.toISOString(),
        end_time: end.toISOString(),
        buffer_end_time: bufferEnd.toISOString(),
        amount_bif: service.price_bif,
        notes: notes ?? null,
        status: "confirmed",
        payment_status: "pending",
        payment_method: "cash",
      })
      .select()
      .single();

    if (insertError) {
      if (insertError.code === "23505") {
        return jsonResponse(
          { error: "slot_taken", message: "Ce créneau vient d'être réservé." },
          409,
        );
      }
      throw insertError;
    }

    await supabase.from("activity_logs").insert({
      salon_id: salonId,
      user_id: caller.id,
      type_action: "booking_created",
      new_values: { bookingId: booking.id, walkIn: true },
    });

    return jsonResponse({ booking }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_walkin_booking_failed", message }, 500);
  }
});
