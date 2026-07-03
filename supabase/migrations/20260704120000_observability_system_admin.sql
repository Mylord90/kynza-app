-- Phase 2 (Backend Enterprise Completion) — Observability Enterprise, Track A
-- + the SYSTEM_ADMIN scope Phase 1's audit found missing.
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8.

-- ─── SYSTEM_ADMIN scope (Phase 1 audit finding, docs/backend-completion/ ────
-- PHASE_1_FINAL_AUDIT.md §3 item 9) — additive, does not touch the existing
-- owner/manager/staff/client role enum. A system admin is layered ON TOP of
-- whatever salon-tenant role a user already has (an owner can also be a
-- KYNZA-internal system admin) rather than replacing the tenant RBAC model.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_system_admin BOOLEAN NOT NULL DEFAULT false;

-- Extend the existing protect_user_columns trigger (20260623120000) so
-- is_system_admin is immutable via the client API, same discipline as
-- salon_id/email_verified/reliability_score/role.
CREATE OR REPLACE FUNCTION public.protect_user_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF NEW.salon_id IS DISTINCT FROM OLD.salon_id THEN
      RAISE EXCEPTION 'salon_id is immutable via client API';
    END IF;
    IF NEW.email_verified IS DISTINCT FROM OLD.email_verified THEN
      RAISE EXCEPTION 'email_verified is immutable via client API';
    END IF;
    IF NEW.reliability_score IS DISTINCT FROM OLD.reliability_score THEN
      RAISE EXCEPTION 'reliability_score is immutable via client API';
    END IF;
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'role is immutable via client API';
    END IF;
    IF NEW.is_system_admin IS DISTINCT FROM OLD.is_system_admin THEN
      RAISE EXCEPTION 'is_system_admin is immutable via client API';
    END IF;
  END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.has_system_admin(_uid UUID)
RETURNS BOOLEAN LANGUAGE sql SECURITY INVOKER STABLE SET search_path = public, pg_temp AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = _uid AND u.is_system_admin = true AND u.deleted_at IS NULL
  );
$$;

-- ─── edge_function_invocations (new — Edge Function Dashboard) ────────────
-- Only create-booking is wired to write here in this phase (proof of the
-- pipeline, the highest-traffic function) — the remaining 19 functions are
-- an explicit, documented follow-up, not silently claimed complete.

CREATE TABLE IF NOT EXISTS public.edge_function_invocations (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  function_name TEXT       NOT NULL,
  status       TEXT        NOT NULL CHECK (status IN ('success', 'error')),
  duration_ms  INT,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.edge_function_invocations ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_edge_function_invocations_name_time
  ON public.edge_function_invocations(function_name, occurred_at DESC);

-- Read = system admins only (this is an ops/infra surface, not a
-- salon-tenant concern). Write = service_role only (Edge Functions).
CREATE POLICY "edge_function_invocations_admin_select"
  ON public.edge_function_invocations FOR SELECT TO authenticated
  USING (public.has_system_admin(auth.uid()));

-- ─── v_supabase_dashboard — serves both "System Metrics" and "Supabase ────
-- Dashboard" from the brief (they measure the same underlying thing:
-- schema health) — one real view, two UI cards surfacing different columns,
-- documented as an intentional consolidation in PHASE_2_OBSERVABILITY.md,
-- not a silently dropped item.

CREATE OR REPLACE VIEW public.v_supabase_dashboard
AS
SELECT
  (SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS table_count,
  (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') AS policy_count,
  (SELECT COUNT(DISTINCT tablename) FROM pg_policies WHERE schemaname = 'public') AS tables_with_rls_count,
  (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') AS index_count,
  (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public') AS view_count,
  (SELECT COUNT(*) FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_type = 'FUNCTION') AS function_count,
  now() AS snapshot_at;

-- ─── v_storage_dashboard — real Supabase Storage bucket usage ─────────────

CREATE OR REPLACE VIEW public.v_storage_dashboard AS
SELECT
  bucket_id,
  COUNT(*) AS object_count,
  COALESCE(SUM((metadata->>'size')::BIGINT), 0) AS total_bytes
FROM storage.objects
GROUP BY bucket_id;

-- ─── v_notification_dashboard — real delivery stats from notification_logs

CREATE OR REPLACE VIEW public.v_notification_dashboard
AS
SELECT
  channel,
  DATE_TRUNC('day', created_at) AS day,
  COUNT(*) AS total_sent,
  COUNT(*) FILTER (WHERE delivered = true) AS delivered_count,
  COUNT(*) FILTER (WHERE delivered = false) AS failed_count
FROM public.notification_logs
WHERE created_at > now() - INTERVAL '30 days'
GROUP BY channel, DATE_TRUNC('day', created_at);

-- ─── v_queue_dashboard — real automation queue depth/health ───────────────

CREATE OR REPLACE VIEW public.v_queue_dashboard
AS
SELECT
  'automation_action_runs' AS queue_name,
  status,
  COUNT(*) AS row_count
FROM public.automation_action_runs
GROUP BY status
UNION ALL
SELECT
  'automation_execution_logs' AS queue_name,
  status,
  COUNT(*) AS row_count
FROM public.automation_execution_logs
GROUP BY status;

-- ─── v_edge_function_dashboard — real, but only create-booking populates it

CREATE OR REPLACE VIEW public.v_edge_function_dashboard
AS
SELECT
  function_name,
  COUNT(*) AS total_invocations,
  COUNT(*) FILTER (WHERE status = 'error') AS error_count,
  ROUND(AVG(duration_ms)) AS avg_duration_ms,
  MAX(occurred_at) AS last_invocation_at
FROM public.edge_function_invocations
WHERE occurred_at > now() - INTERVAL '7 days'
GROUP BY function_name;

-- ─── v_crash_dashboard — real, populated once CrashReportingService dual- ──
-- logs to activity_logs (this phase's Flutter change); severity-filtered
-- rows only, never PII (activity_logs.new_values already excludes PII by
-- existing convention).

CREATE OR REPLACE VIEW public.v_crash_dashboard
AS
SELECT
  DATE_TRUNC('day', created_at) AS day,
  severity,
  COUNT(*) AS event_count
FROM public.activity_logs
WHERE type_action = 'client_error_logged'
  AND created_at > now() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at), severity;

-- ─── v_security_dashboard — real rate-limit pressure + RLS coverage ───────

CREATE OR REPLACE VIEW public.v_security_dashboard
AS
SELECT
  key,
  window_start,
  count,
  now() AS snapshot_at
FROM public.rate_limit_buckets
WHERE window_start > now() - INTERVAL '1 hour'
ORDER BY count DESC;

-- ─── Access control for all 7 views above ──────────────────────────────────
-- Plain Postgres views cannot carry RLS themselves. Rather than GRANT SELECT
-- to `authenticated` (which would let any tenant read cross-tenant aggregate
-- data — a real leak for e.g. v_security_dashboard's rate-limit keys, which
-- can embed other users' ids), every view is read ONLY through a matching
-- SECURITY DEFINER RPC that checks has_system_admin(auth.uid()) first and
-- raises before touching the view otherwise. No view itself is granted to
-- `authenticated`/`anon` — the RPC is the only path, same enforcement shape
-- as refresh_audit_stats()'s existing SECURITY DEFINER + explicit REVOKE
-- pattern (20260629110000_audit_enterprise.sql), extended here with an
-- in-function role check since, unlike that function, these must remain
-- callable by authenticated users (and rejected for non-admins), not
-- revoked outright.

CREATE OR REPLACE FUNCTION public.get_supabase_dashboard()
RETURNS SETOF public.v_supabase_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_supabase_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_storage_dashboard()
RETURNS SETOF public.v_storage_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_storage_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_notification_dashboard()
RETURNS SETOF public.v_notification_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_notification_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_queue_dashboard()
RETURNS SETOF public.v_queue_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_queue_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_edge_function_dashboard()
RETURNS SETOF public.v_edge_function_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_edge_function_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_crash_dashboard()
RETURNS SETOF public.v_crash_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_crash_dashboard;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_security_dashboard()
RETURNS SETOF public.v_security_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_security_dashboard;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_supabase_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_storage_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_notification_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_queue_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_edge_function_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_crash_dashboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_security_dashboard() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_supabase_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_storage_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_notification_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_queue_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_edge_function_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_crash_dashboard() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_security_dashboard() FROM anon;

-- ─── Whitelist extension for CrashReportingService's new dual-log ─────────
-- Extends logs_self_insert_safe (same pattern as Phase 3's CP2 change) so
-- CrashReportingService.recordError() can write a severity-tagged row for
-- v_crash_dashboard/get_crash_dashboard() to aggregate.

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
      'permission_group_member_added', 'permission_group_member_removed',
      'settings_changed',
      'feature_flag_override_set', 'feature_flag_override_removed',
      'client_error_logged'
    )
  );
