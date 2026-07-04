-- DRAFT — reviewed but NOT applied to any project, per Rule 8. Companion migration for CP11's
-- Edge Function code patch (supabase/functions/run-scheduled-actions/index.ts,
-- supabase/functions/schedule-reminders/index.ts) — see
-- docs/certification-v2/CP4_EDGE_FUNCTION_REVERIFY.md and CP11's virtual-PR notes.
--
-- FINDING: both functions relied on platform-level verify_jwt as their only gate, but verify_jwt
-- is satisfied by the public anon key shipped in the Flutter app — it never actually restricted
-- these two "cron-only" functions to the real scheduler. The Edge Function patch now requires an
-- `X-Cron-Secret` header matching a `CRON_SECRET` Edge Function secret. This migration updates
-- the two pg_cron jobs to send that header, sourced from Vault the same way `project_url` and
-- `service_role_key` already are.
--
-- ⚠ PRECONDITIONS BEFORE APPLYING (both required, neither done by this migration):
-- 1. Set the `CRON_SECRET` Edge Function secret: `supabase secrets set CRON_SECRET=<a-real-random-value> --project-ref <target>`
-- 2. Store the same value in Vault under the name 'cron_secret':
--    `SELECT vault.create_secret('<the-same-random-value>', 'cron_secret');`
-- Applying this migration before both of those exist will make the cron jobs send a NULL/mismatched
-- header, and the two functions will 403 on every scheduled run — reminders and workflow actions
-- would silently stop firing. This is exactly the kind of precondition Rule 8 exists to catch
-- before a migration reaches production.

SELECT cron.unschedule('schedule-reminders-hourly')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'schedule-reminders-hourly');

SELECT cron.schedule(
  'schedule-reminders-hourly',
  '0 * * * *',
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/schedule-reminders',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'X-Cron-Secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);

SELECT cron.unschedule('run-scheduled-actions-5min')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'run-scheduled-actions-5min');

SELECT cron.schedule(
  'run-scheduled-actions-5min',
  '*/5 * * * *',
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/run-scheduled-actions',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'X-Cron-Secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);

-- NOTE: the existing job names in production were not confirmed this pass (CP6's pg_cron query
-- returned jobid/schedule/command but this draft assumes conventional names based on the schedule
-- shape — 'schedule-reminders-hourly' for the "0 * * * *" job calling schedule-reminders, and
-- 'run-scheduled-actions-5min' for the "*/5 * * * *" job calling run-scheduled-actions). Confirm
-- actual jobnames via `SELECT jobid, jobname, schedule FROM cron.job;` before applying — the
-- `WHERE EXISTS` guards make an unschedule-of-a-nonexistent-name a silent no-op rather than an
-- error, but a name mismatch would leave the OLD (unsecured) job running unmodified alongside a
-- new one, doubling the reminder frequency. Verify names match exactly first.
