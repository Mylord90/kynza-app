// supabase/functions/check-system-alerts/index.ts
// CP6 (Enterprise Resilience & Reliability Certification) — the alerting
// mechanism the prior validation pass found didn't exist at all. Cron-driven
// (every 5 minutes, mirroring run-scheduled-actions' interval — a matching
// pg_cron job is a documented follow-up, not created here since it would
// need to run against production, out of scope for a draft). Calls
// check_system_alerts() (migration 20260705110000), which evaluates all 3
// thresholds and returns only newly-triggered alerts (already de-duplicated
// server-side against any still-open alert of the same type). For each new
// alert, dispatches a WhatsApp message to the configured ops contact —
// reusing the same _shared/whatsapp.ts helper send-notification already
// relies on, so this doesn't introduce a second WhatsApp integration.
//
// DRAFT ONLY — not deployed, per Rule 8.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient } from "../_shared/supabase_admin.ts";
import { sendWhatsappText } from "../_shared/whatsapp.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  // Same cron-secret gate as run-scheduled-actions/schedule-reminders —
  // this must only ever be invoked by the scheduler, never a client.
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret || req.headers.get("X-Cron-Secret") !== cronSecret) {
    return jsonResponse({ error: "forbidden" }, 403);
  }

  try {
    const admin = createServiceRoleClient();

    const { data: newAlerts, error } = await admin.rpc("check_system_alerts");
    if (error) throw error;

    const opsNumber = Deno.env.get("OPS_ALERT_WHATSAPP_NUMBER");
    let dispatched = 0;

    for (const alert of newAlerts ?? []) {
      if (!opsNumber) continue; // Best-effort: still recorded in system_alerts either way.
      try {
        await sendWhatsappText(
          opsNumber,
          `🚨 KYNZA ALERT [${alert.severity}] ${alert.alert_type}\n${alert.message}`,
        );
        dispatched++;
      } catch {
        // A failed WhatsApp send must never block evaluating/recording the
        // next alert — the alert row itself is already committed by
        // check_system_alerts(), so it's never silently lost even if
        // delivery fails here.
      }
    }

    return jsonResponse(
      { status: "checked", newAlerts: newAlerts?.length ?? 0, dispatched },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    return jsonResponse({ error: "check_system_alerts_failed", message }, 500);
  }
});
