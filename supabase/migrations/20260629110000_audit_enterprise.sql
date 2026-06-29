-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.2 — Audit Enterprise
--
-- Extends the existing append-only activity_logs (foundation migration)
-- rather than rebuilding it. Audited every existing write site first:
-- the table already has old_values/new_values (plural, JSONB) and
-- ip_address — the brief assumed singular old_value/new_value and asked
-- to re-add ip_address; both skipped to avoid duplicate columns. The
-- brief's idx_audit_salon_created is also identical to the foundation
-- migration's existing idx_logs_salon(salon_id, created_at DESC) — not
-- recreated either.
-- ================================================================

ALTER TABLE public.activity_logs
  ADD COLUMN IF NOT EXISTS device_info JSONB,
  ADD COLUMN IF NOT EXISTS platform TEXT,
  ADD COLUMN IF NOT EXISTS app_version TEXT,
  ADD COLUMN IF NOT EXISTS screen_name TEXT,
  ADD COLUMN IF NOT EXISTS record_id UUID,
  ADD COLUMN IF NOT EXISTS table_name TEXT,
  ADD COLUMN IF NOT EXISTS session_id TEXT,
  ADD COLUMN IF NOT EXISTS request_id TEXT,
  ADD COLUMN IF NOT EXISTS duration_ms INTEGER,
  ADD COLUMN IF NOT EXISTS is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS severity TEXT NOT NULL DEFAULT 'info'
    CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical'));

CREATE INDEX IF NOT EXISTS idx_audit_user_action
  ON public.activity_logs(user_id, type_action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_table_record
  ON public.activity_logs(table_name, record_id) WHERE record_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_severity
  ON public.activity_logs(severity, created_at DESC)
  WHERE severity IN ('warning', 'error', 'critical');

-- Whitelist fix found while auditing every existing INSERT call site:
-- 4 type_action values already written in production by Edge Functions
-- (service_role, bypasses RLS) were missing from logs_self_insert_safe's
-- whitelist — harmless today since none of those 4 are ever inserted via
-- an authenticated client session, but the whitelist is supposed to be
-- the authoritative list of valid actions. Also adds the new permission-
-- group and auth values this phase's AuditLogger actually writes from
-- Flutter (subject to this policy, unlike the service-role Edge Function
-- inserts above).
DROP POLICY IF EXISTS "logs_self_insert_safe" ON public.activity_logs;
CREATE POLICY "logs_self_insert_safe" ON public.activity_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND salon_id IN (SELECT salon_id FROM public.users WHERE id = auth.uid())
    AND type_action IN (
      'user_login', 'user_logout', 'profile_updated', 'role_changed',
      'salon_updated', 'salon_status_changed',
      'staff_invited', 'staff_removed', 'staff_invitation_accepted',
      'booking_created', 'booking_confirmed', 'booking_cancelled',
      'booking_completed', 'booking_no_show',
      'payment_completed', 'payment_failed', 'refund_initiated',
      'discount_applied', 'referral_claimed',
      'loyalty_stamp_added', 'loyalty_reward_redeemed',
      'permission_group_created', 'permission_group_deleted',
      'permission_group_permission_changed',
      'permission_group_member_added', 'permission_group_member_removed'
    )
  );

-- Hourly rollup for an audit-stats dashboard (none exists yet — this just
-- establishes the aggregate + refresh plumbing per the brief). Kept
-- internal: granted to no client role yet, since nothing consumes it.
-- A future salon-scoped consumer must wrap it in a security_invoker view
-- (Postgres has no RLS on materialized views) rather than be granted
-- direct SELECT, or every salon's stats would be readable by any user.
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_audit_stats AS
SELECT
  salon_id,
  DATE_TRUNC('day', created_at) AS day,
  type_action,
  severity,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users
FROM public.activity_logs
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY salon_id, DATE_TRUNC('day', created_at), type_action, severity;

-- REFRESH ... CONCURRENTLY requires a unique index; GROUP BY above already
-- guarantees this combination is unique per row.
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_audit_stats
  ON public.mv_audit_stats(salon_id, day, type_action, severity);

CREATE OR REPLACE FUNCTION public.refresh_audit_stats()
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_audit_stats;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.refresh_audit_stats() FROM authenticated, anon, public;

CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'kynza-refresh-audit-stats',
  '0 * * * *', -- hourly
  $$SELECT public.refresh_audit_stats();$$
);