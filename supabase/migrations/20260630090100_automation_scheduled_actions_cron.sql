-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 2 follow-up.
-- Every 5 minutes, calls run-scheduled-actions to process due
-- delay_seconds actions and failed-action retries. Same pg_cron +
-- pg_net + Vault-secret pattern as kynza-booking-reminders
-- (20260624062000) — assumes the 'project_url'/'service_role_key' Vault
-- secrets already exist (created once out-of-band by an operator).
-- ================================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.schedule(
  'kynza-run-scheduled-actions',
  '*/5 * * * *', -- every 5 minutes
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/run-scheduled-actions',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);