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

SELECT cron.unschedule('kynza-booking-reminders')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'kynza-booking-reminders');

SELECT cron.schedule(
  'kynza-booking-reminders',
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

SELECT cron.unschedule('kynza-run-scheduled-actions')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'kynza-run-scheduled-actions');

SELECT cron.schedule(
  'kynza-run-scheduled-actions',
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

-- UPDATE (Remediation v1, Phase 2): the CP11 draft above assumed conventional job names
-- ('schedule-reminders-hourly'/'run-scheduled-actions-5min') that were never actually confirmed
-- against a real `cron.job` query. Both kynza-dr-scratch and production (read-only check) were
-- queried directly this phase: the real names are `kynza-booking-reminders` (0 * * * *) and
-- `kynza-run-scheduled-actions` (*/5 * * * *), identical on both projects. Corrected above —
-- this was a real bug in the original draft that would have left the old, unsecured jobs running
-- unmodified alongside new ones, doubling reminder/action-runner frequency, exactly the risk the
-- original draft's own note warned about.
