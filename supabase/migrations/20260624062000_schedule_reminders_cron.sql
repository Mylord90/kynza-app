-- ================================================================
-- KYNZA — Migration 019 — Phase 2.2 / Module 1 — Booking reminders cron
-- Hourly pg_cron job that calls the schedule-reminders Edge Function via
-- pg_net. The Edge Function URL and service_role key are never hardcoded
-- here (R16/security skill §5) — this migration assumes two secrets
-- already exist in Supabase Vault, created once out-of-band by an
-- operator (NOT via a committed migration):
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<service_role_key>', 'service_role_key');
-- ================================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.schedule(
  'kynza-booking-reminders',
  '0 * * * *', -- every hour, on the hour
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/schedule-reminders',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);
