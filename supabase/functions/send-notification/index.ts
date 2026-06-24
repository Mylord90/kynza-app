// supabase/functions/send-notification/index.ts
// Best-effort push — never throws, always returns 200 (notifications are
// never allowed to block the financial/booking flow that triggered them).
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { sendFcmPush } from "../_shared/fcm.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

const TEMPLATES: Record<string, (data: Record<string, unknown>) => { title: string; body: string }> = {
  booking_confirmed: () => ({
    title: "Réservation confirmée ✅",
    body: "Votre rendez-vous est confirmé. À très bientôt !",
  }),
  booking_reminder: (d) => ({
    title: "Rappel KYNZA",
    body: `Votre RDV est ${d.window === "h2" ? "dans 2h" : "demain"}.`,
  }),
  booking_cancelled: () => ({
    title: "RDV annulé",
    body: "Votre rendez-vous a été annulé.",
  }),
};

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const { bookingId, event, window } = await req.json();
    if (!bookingId || !event || !TEMPLATES[event]) {
      return jsonResponse({ error: "missing_or_unknown_event" }, 400);
    }

    const supabase = createServiceRoleClient();
    const { data: booking } = await supabase
      .from("bookings")
      .select("client_id, users:client_id(fcm_token)")
      .eq("id", bookingId)
      .single();

    const fcmToken = (booking?.users as { fcm_token?: string } | null)?.fcm_token;
    if (fcmToken) {
      const { title, body } = TEMPLATES[event]({ window });
      await sendFcmPush(fcmToken, {
        title,
        body,
        data: { deepLink: `/booking/${bookingId}`, event },
      });
    }

    return jsonResponse({ status: "sent" }, 200);
  } catch (_e) {
    // Best-effort: log server-side only, never surface a failure to the caller.
    return jsonResponse({ status: "skipped" }, 200);
  }
});
