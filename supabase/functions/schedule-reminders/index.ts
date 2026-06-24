// supabase/functions/schedule-reminders/index.ts
// Called by pg_cron every hour (see migration 20260624062000). Finds
// confirmed/in_progress bookings landing in the next ~24h or ~2h window
// and fires the matching reminder template via send-notification.
// Idempotent: skips a (booking, event_type) pair already present in
// notification_logs so an hourly run never double-reminds.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";

const ACTIVE_STATUSES = ["confirmed", "in_progress"];

interface ReminderWindow {
  eventType: "booking_reminder_24h" | "booking_reminder_2h";
  windowStart: Date;
  windowEnd: Date;
}

function windowsFor(now: Date): ReminderWindow[] {
  const h = (n: number) => n * 3600_000;
  return [
    {
      eventType: "booking_reminder_24h",
      windowStart: new Date(now.getTime() + h(24) - h(0.5)),
      windowEnd: new Date(now.getTime() + h(24) + h(0.5)),
    },
    {
      eventType: "booking_reminder_2h",
      windowStart: new Date(now.getTime() + h(2) - h(0.25)),
      windowEnd: new Date(now.getTime() + h(2) + h(0.25)),
    },
  ];
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const supabase = createServiceRoleClient();
    const now = new Date();
    let sent = 0;

    for (const window of windowsFor(now)) {
      const { data: bookings } = await supabase
        .from("bookings")
        .select("id, salon_id, client_id")
        .in("status", ACTIVE_STATUSES)
        .gte("start_time", window.windowStart.toISOString())
        .lt("start_time", window.windowEnd.toISOString())
        .is("deleted_at", null);

      for (const booking of bookings ?? []) {
        const { data: already } = await supabase
          .from("notification_logs")
          .select("id")
          .eq("related_booking_id", booking.id)
          .eq("event_type", window.eventType)
          .limit(1)
          .maybeSingle();
        if (already) continue;

        await supabase.functions.invoke("send-notification", {
          body: { bookingId: booking.id, event: window.eventType },
        });
        sent++;
      }
    }

    return jsonResponse({ status: "ok", sent }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    return jsonResponse({ error: "schedule_reminders_failed", message }, 500);
  }
});
