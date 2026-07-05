// supabase/functions/schedule-reminders/index.ts
// Called by pg_cron every hour (see migration 20260624062000). Finds
// confirmed/in_progress bookings landing in the next ~24h or ~2h window
// and fires the matching reminder template via send-notification.
//
// CP0 (docs/enterprise-resilience/CONCURRENCY_REPORT.md): idempotency used
// to be a plain SELECT-then-invoke check against notification_logs, which
// is a TOCTOU race if two runs ever overlap (an hourly cron job overlapping
// requires a run to take >1h, but that's exactly the kind of "unlikely but
// not impossible, and the blast radius is a real double WhatsApp/push send"
// case CP0 exists to close). Each (booking, event_type) pair is now claimed
// by inserting into reminder_dispatch_claims first — its primary key makes
// a second concurrent claim attempt fail with 23505, so only one caller
// ever proceeds to send — same "insert wins the claim" idiom already used
// by claim-referral and calculate-commission.
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

  // CP4 finding (docs/certification-v2/CP4_EDGE_FUNCTION_REVERIFY.md): platform-level verify_jwt
  // is satisfied by the public anon key shipped in the app, so it was never actually restricting
  // this "cron-only" function to the real scheduler. Requires a dedicated secret the pg_cron job
  // sends (supabase/migrations/20260704220000_cp11_cron_secret.sql) — never reaches the client.
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret || req.headers.get("X-Cron-Secret") !== cronSecret) {
    return jsonResponse({ error: "forbidden" }, 403);
  }

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
        const { error: claimError } = await supabase
          .from("reminder_dispatch_claims")
          .insert({ booking_id: booking.id, event_type: window.eventType });
        if (claimError) {
          if (claimError.code === "23505") continue; // already claimed by another run
          throw claimError;
        }

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
