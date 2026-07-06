-- Go-Live Phase 3 (Production Operations) — registers the pg_cron schedule for
-- check-system-alerts, the one piece P1-12's own row explicitly named as still missing
-- ("no pg_cron schedule created yet — needs a production target"). The Edge Function itself
-- (supabase/functions/check-system-alerts/index.ts, CP6 of Enterprise Resilience) and the
-- underlying check_system_alerts() RPC (migration 20260705110000, applied in Go-Live Phase 2)
-- already exist; this is purely the scheduling half, applied directly to production per this
-- phase's own explicit authorization ("deploy the cron/scheduled jobs").
--
-- Every 5 minutes, matching run-scheduled-actions' interval and the Edge Function's own header
-- comment ("Cron-driven (every 5 minutes, mirroring run-scheduled-actions' interval")). Same
-- X-Cron-Secret/Vault pattern as every other cron-driven function in this project.

SELECT cron.schedule(
  'kynza-check-system-alerts',
  '*/5 * * * *',
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/check-system-alerts',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'X-Cron-Secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);
