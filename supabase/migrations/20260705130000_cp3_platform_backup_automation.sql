-- Master Plan Execution CP3 — closes P1-3's residual item (Master Plan §2:
-- "no recurring/automated backup exists... RPO is not fixed, it is
-- currently rising"). Converts the one-time manual backup
-- (docs/remediation/PHASE_0_BACKUP_CONFIRMED.md) into a scheduled job.
--
-- Shares the exact `X-Cron-Secret`/Vault pattern already used by
-- `kynza-booking-reminders`/`kynza-run-scheduled-actions`
-- (20260704220000_cp11_cron_secret.sql) — same precondition applies:
-- `CRON_SECRET` must exist as both an Edge Function secret and a Vault
-- entry named 'cron_secret' *before* this applies, or the job silently
-- 403s on every run.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Master Plan Execution CP3), where the cron job really
-- runs (dr-scratch already has CRON_SECRET wired for the existing 2 jobs —
-- see docs/remediation/PHASE_2_SECURITY_FIXES.md §5b).

CREATE TABLE IF NOT EXISTS public.platform_backup_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  storage_prefix TEXT,
  tables_exported INT,
  rows_exported INT,
  total_bytes BIGINT,
  error_message TEXT
);

ALTER TABLE public.platform_backup_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "platform_backup_jobs_admin_select" ON public.platform_backup_jobs
  FOR SELECT TO authenticated USING (public.has_system_admin(auth.uid()));
-- No INSERT/UPDATE/DELETE policy — only service_role (the Edge Function
-- below) ever writes here, same deny-all-by-omission pattern already used
-- by reminder_dispatch_claims/data_deletion_requests.

-- Enumerates every real table create-platform-backup needs to export,
-- without hardcoding a table list that would silently go stale the next
-- time a migration adds one (unlike Phase 0's one-time manual export,
-- which listed tables by hand because it was never meant to repeat).
CREATE OR REPLACE FUNCTION public.get_all_public_tables()
RETURNS TABLE(table_name TEXT)
LANGUAGE sql SECURITY DEFINER SET search_path = public, pg_temp AS $$
  SELECT c.relname::TEXT
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r'
  ORDER BY c.relname;
$$;

REVOKE ALL ON FUNCTION public.get_all_public_tables() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_all_public_tables() TO service_role;

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Every 6 hours (matches create-backup's own per-salon cooldown constant,
-- a deliberately un-aggressive default — bounds RPO at <=6h instead of the
-- unbounded, ever-growing gap a one-time backup leaves). Cadence is a
-- config value, not an architectural limit — trivial to tighten later via
-- `cron.alter_job` once real production write volume justifies it.
SELECT cron.schedule(
  'kynza-platform-backup',
  '0 */6 * * *',
  $$
    SELECT net.http_post(
      url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
        || '/functions/v1/create-platform-backup',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key'),
        'X-Cron-Secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret'),
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    );
  $$
);
