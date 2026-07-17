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
import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
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

  const bodyGuard = await readBodyGuarded(req);
  if (!bodyGuard.ok) return bodyGuard.response;

  try {
    const payload: NotificationPayload = JSON.parse(bodyGuard.text);
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
      .select("whatsapp_phone, whatsapp_opt_in")
      .eq("id", userId)
      .single();

    // device_tokens, not users.fcm_token (Phase 1b Étape 2): a user can
    // have N devices now, not just one.
    const { data: deviceTokens } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId)
      .is("deleted_at", null);

    const pushOk = prefs?.push_enabled ?? true;
    const whatsappOk = prefs?.whatsapp_enabled ?? true;

    if (pushOk && channels.includes("push") && deviceTokens && deviceTokens.length > 0) {
      // Same payload for every device — computed once, not per token.
      const pushPayload = {
        title,
        body,
        data: {
          event_type: payload.event,
          booking_id: relatedBookingId ?? "",
          // relatedBookingId here only gates WHETHER this is a
          // booking-related event — the target below doesn't use the id
          // itself. Do not "simplify" this ternary to a plain string:
          // dropping the check would make every non-booking event (e.g.
          // staff_joined) deep-link into the bookings list too. No
          // client-side booking detail screen exists yet (a separate,
          // future product ticket) so the list is the target that's
          // never wrong — paid, cancelled, or upcoming, the booking is
          // findable there — unlike /client/payment/:id, a live payment
          // tunnel that no booking past pending_payment should reopen.
          deepLink: relatedBookingId ? "/client/bookings" : "",
        },
      };

      // Aggregate policy (deliberate, not a schema gap): one
      // notification_logs row per notification per user, not per device —
      // delivered = true if at least one of the user's devices succeeded.
      // The product question is "was the user notified", not "which of
      // their N phones got it". Zero schema change needed for this.
      //
      // Honest caveat, not the wished-for semantics: sendFcmPush()
      // (_shared/fcm.ts) swallows every error internally and never reads
      // the fetch() response body, so it never actually throws for a
      // rejected/invalid token today. In practice `delivered` here
      // currently means "we called fetch N times without a JS-level
      // exception", not "FCM confirmed delivery to at least one device".
      // Fixing that is a separate ticket (_shared/fcm.ts needs to read
      // FCM's response and propagate NOT_REGISTERED/INVALID_ARGUMENT) —
      // this aggregate is already the right shape for the day that ships,
      // so it won't need a second logic change then.
      let delivered = false;
      let deliveryError: string | null = null;
      for (const { token } of deviceTokens) {
        try {
          await sendFcmPush(token, pushPayload);
          delivered = true;
        } catch (e) {
          deliveryError ??= e instanceof Error ? e.message : "fcm_send_failed";
        }
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
        delivery_error: delivered ? null : deliveryError,
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
