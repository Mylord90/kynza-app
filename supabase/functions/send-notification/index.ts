// supabase/functions/send-notification/index.ts
// Best-effort dispatcher — never throws, always returns 200 (a failed
// notification must never block the booking/payment flow that triggered
// it). Looks up the DB template for `event`, interpolates it, then fans
// out to every enabled channel and logs one notification_logs row per
// channel actually attempted, plus one `in_app` row always.
//
// Two calling conventions are supported:
//  - { bookingId, event }            — booking-shaped events (existing
//    caller: leapa-webhook). userId/salonId/template variables are
//    derived from the booking + its salon/service.
//  - { userId, event, salonId?, relatedBookingId?, data? } — direct
//    events with no booking context (e.g. staff_joined).
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { sendFcmPush } from "../_shared/fcm.ts";
import { sendWhatsappText } from "../_shared/whatsapp.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

interface NotificationPayload {
  event: string;
  bookingId?: string;
  userId?: string;
  salonId?: string;
  relatedBookingId?: string;
  data?: Record<string, string>;
}

function formatDateFr(iso: string): { date: string; time: string } {
  const d = new Date(iso);
  return {
    date: d.toLocaleDateString("fr-FR", { day: "2-digit", month: "2-digit", year: "numeric" }),
    time: d.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" }),
  };
}

function interpolate(text: string, vars: Record<string, string>): string {
  let out = text;
  for (const [key, value] of Object.entries(vars)) {
    out = out.replaceAll(`{{${key}}}`, value);
  }
  return out;
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const payload: NotificationPayload = await req.json();
    if (!payload.event) return jsonResponse({ error: "missing_event" }, 400);

    const supabase = createServiceRoleClient();

    let userId = payload.userId;
    let salonId = payload.salonId;
    const relatedBookingId = payload.relatedBookingId ?? payload.bookingId;
    const vars: Record<string, string> = { ...(payload.data ?? {}) };

    if (payload.bookingId) {
      const { data: booking } = await supabase
        .from("bookings")
        .select("client_id, salon_id, start_time, salons(name), services(name)")
        .eq("id", payload.bookingId)
        .single();

      if (booking) {
        userId = booking.client_id;
        salonId = booking.salon_id;
        const { date, time } = formatDateFr(booking.start_time);
        vars.salon_name ??= (booking.salons as { name?: string } | null)?.name ?? "";
        vars.service_name ??= (booking.services as { name?: string } | null)?.name ?? "";
        vars.date ??= date;
        vars.time ??= time;
      }
    }

    if (!userId) return jsonResponse({ error: "missing_user" }, 400);

    const { data: template } = await supabase
      .from("notification_templates")
      .select("*")
      .eq("event_type", payload.event)
      .eq("is_active", true)
      .maybeSingle();

    if (!template) return jsonResponse({ status: "skipped", reason: "no_template" }, 200);

    const title = interpolate(template.title_fr, vars);
    const body = interpolate(template.body_fr, vars);
    const channels: string[] = template.channels ?? ["push"];

    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("*")
      .eq("user_id", userId)
      .maybeSingle();

    const { data: user } = await supabase
      .from("users")
      .select("fcm_token, whatsapp_phone, whatsapp_opt_in")
      .eq("id", userId)
      .single();

    const pushOk = prefs?.push_enabled ?? true;
    const whatsappOk = prefs?.whatsapp_enabled ?? true;

    if (pushOk && channels.includes("push") && user?.fcm_token) {
      let delivered = true;
      let deliveryError: string | null = null;
      try {
        await sendFcmPush(user.fcm_token, {
          title,
          body,
          data: {
            event_type: payload.event,
            booking_id: relatedBookingId ?? "",
            deepLink: relatedBookingId ? `/booking/${relatedBookingId}` : "",
          },
        });
      } catch (e) {
        delivered = false;
        deliveryError = e instanceof Error ? e.message : "fcm_send_failed";
      }
      await supabase.from("notification_logs").insert({
        user_id: userId,
        salon_id: salonId ?? null,
        event_type: payload.event,
        channel: "push",
        title,
        body,
        data: vars,
        related_booking_id: relatedBookingId ?? null,
        delivered,
        delivery_error: deliveryError,
      });
    }

    if (whatsappOk && channels.includes("whatsapp") && user?.whatsapp_phone && user?.whatsapp_opt_in) {
      let delivered = true;
      let deliveryError: string | null = null;
      try {
        await sendWhatsappText(user.whatsapp_phone, `${title}\n\n${body}`);
      } catch (e) {
        delivered = false;
        deliveryError = e instanceof Error ? e.message : "whatsapp_send_failed";
      }
      await supabase.from("notification_logs").insert({
        user_id: userId,
        salon_id: salonId ?? null,
        event_type: payload.event,
        channel: "whatsapp",
        title,
        body,
        data: vars,
        related_booking_id: relatedBookingId ?? null,
        delivered,
        delivery_error: deliveryError,
      });
    }

    // Always logged regardless of preferences — this is what powers the
    // in-app notification center, distinct from the push/whatsapp sends.
    await supabase.from("notification_logs").insert({
      user_id: userId,
      salon_id: salonId ?? null,
      event_type: payload.event,
      channel: "in_app",
      title,
      body,
      data: vars,
      related_booking_id: relatedBookingId ?? null,
      delivered: true,
    });

    return jsonResponse({ status: "sent" }, 200);
  } catch (_e) {
    // Best-effort: never surface a notification failure to the caller.
    return jsonResponse({ status: "skipped" }, 200);
  }
});
