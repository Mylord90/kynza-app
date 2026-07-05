-- CP6 (Enterprise Resilience & Reliability Certification) — the missing
-- pieces the Final Enterprise Validation pass's direct verdict named:
-- "not production-observable today." That pass found the monitoring table
-- (20260704120000_observability_system_admin.sql) is one of 16 migrations
-- never deployed, and confirmed no alerting mechanism exists anywhere.
-- This migration does NOT redo that finding — it drafts what closes it:
-- a payment-failure dashboard (the one metric CP6 asks for that the prior
-- draft didn't cover) and a real threshold-based alerting mechanism.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (see docs/enterprise-resilience/OBSERVABILITY_ADVANCED_REPORT.md).
-- Depends on 20260704120000_observability_system_admin.sql (has_system_admin,
-- edge_function_invocations) already being applied first.

-- ─── v_payment_dashboard — real payment failure-rate visibility ───────────
-- (transactions.status already distinguishes completed/failed/expired/
-- reversed — this just aggregates it; no new write path needed)

CREATE OR REPLACE VIEW public.v_payment_dashboard AS
SELECT
  DATE_TRUNC('hour', created_at) AS hour,
  method,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed_count,
  COUNT(*) FILTER (WHERE status = 'failed') AS failed_count,
  COUNT(*) FILTER (WHERE status = 'expired') AS expired_count,
  COUNT(*) FILTER (WHERE status = 'reversed') AS reversed_count
FROM public.transactions
WHERE created_at > now() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('hour', created_at), method;

CREATE OR REPLACE FUNCTION public.get_payment_dashboard()
RETURNS SETOF public.v_payment_dashboard
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.v_payment_dashboard;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_payment_dashboard() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_payment_dashboard() FROM anon;

-- ─── system_alerts — the alerting mechanism that didn't exist at all ─────

CREATE TABLE IF NOT EXISTS public.system_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL CHECK (alert_type IN (
    'edge_function_error_rate', 'sync_queue_depth', 'payment_failure_rate'
  )),
  severity TEXT NOT NULL CHECK (severity IN ('warning', 'critical')),
  message TEXT NOT NULL,
  metric_value NUMERIC,
  threshold_value NUMERIC,
  triggered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

-- One open (unresolved) alert per type at a time — mirrors CP0's atomic-
-- claim discipline: check_system_alerts() below queries this partial index
-- before inserting, so a 5-minute-cron re-run while an incident is still
-- ongoing doesn't spam a new alert row every cycle.
CREATE UNIQUE INDEX IF NOT EXISTS idx_system_alerts_one_open_per_type
  ON public.system_alerts (alert_type) WHERE resolved_at IS NULL;

ALTER TABLE public.system_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "system_alerts_admin_select" ON public.system_alerts
  FOR SELECT TO authenticated USING (public.has_system_admin(auth.uid()));

-- ─── check_system_alerts() — evaluates all 3 thresholds, inserts + ───────
-- returns any newly-triggered alert. Designed to be called by a cron-driven
-- Edge Function (check-system-alerts, draft) every 5 minutes; also callable
-- directly for the live incident-simulation test this checkpoint runs.
--
-- Thresholds (documented here, not just in code, since this function IS
-- the spec): edge function error rate > 10% (min 10 invocations in the
-- window, to avoid a false alarm from e.g. 1 error out of 2 calls); sync
-- queue depth: oldest still-pending/processing automation_action_runs row
-- is > 30 minutes old (staleness is a better signal than raw row count for
-- a low-volume system — 5 old rows stuck for an hour matters more than 50
-- rows that are all seconds old); payment failure rate > 20% (min 5
-- transactions in the window).
CREATE OR REPLACE FUNCTION public.check_system_alerts()
RETURNS SETOF public.system_alerts
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_total_invocations INT;
  v_error_count INT;
  v_error_rate NUMERIC;
  v_queue_depth INT;
  v_oldest_pending_minutes NUMERIC;
  v_payment_total INT;
  v_payment_failed INT;
  v_payment_failure_rate NUMERIC;
  v_row public.system_alerts;
BEGIN
  -- 1. Edge function error rate (last 15 minutes).
  SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'error')
    INTO v_total_invocations, v_error_count
    FROM public.edge_function_invocations
    WHERE occurred_at > now() - INTERVAL '15 minutes';

  IF v_total_invocations >= 10 THEN
    v_error_rate := v_error_count::NUMERIC / v_total_invocations;
    IF v_error_rate > 0.10 THEN
      INSERT INTO public.system_alerts (alert_type, severity, message, metric_value, threshold_value)
      SELECT 'edge_function_error_rate', 'critical',
        format('Edge Function error rate %s%% over last 15 min (%s errors / %s invocations)',
          ROUND(v_error_rate * 100, 1), v_error_count, v_total_invocations),
        v_error_rate, 0.10
      WHERE NOT EXISTS (
        SELECT 1 FROM public.system_alerts
        WHERE alert_type = 'edge_function_error_rate' AND resolved_at IS NULL
      )
      RETURNING * INTO v_row;
      IF v_row.id IS NOT NULL THEN RETURN NEXT v_row; END IF;
    END IF;
  END IF;

  -- 2. Sync queue depth / staleness.
  SELECT COUNT(*), COALESCE(EXTRACT(EPOCH FROM (now() - MIN(scheduled_at))) / 60, 0)
    INTO v_queue_depth, v_oldest_pending_minutes
    FROM public.automation_action_runs
    WHERE status IN ('pending', 'processing');

  IF v_queue_depth > 0 AND v_oldest_pending_minutes > 30 THEN
    INSERT INTO public.system_alerts (alert_type, severity, message, metric_value, threshold_value)
    SELECT 'sync_queue_depth', 'warning',
      format('%s automation_action_runs rows pending/processing; oldest is %s minutes old',
        v_queue_depth, ROUND(v_oldest_pending_minutes, 0)),
      v_oldest_pending_minutes, 30
    WHERE NOT EXISTS (
      SELECT 1 FROM public.system_alerts
      WHERE alert_type = 'sync_queue_depth' AND resolved_at IS NULL
    )
    RETURNING * INTO v_row;
    IF v_row.id IS NOT NULL THEN RETURN NEXT v_row; END IF;
  END IF;

  -- 3. Payment failure rate (last 1 hour).
  SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'failed')
    INTO v_payment_total, v_payment_failed
    FROM public.transactions
    WHERE created_at > now() - INTERVAL '1 hour';

  IF v_payment_total >= 5 THEN
    v_payment_failure_rate := v_payment_failed::NUMERIC / v_payment_total;
    IF v_payment_failure_rate > 0.20 THEN
      INSERT INTO public.system_alerts (alert_type, severity, message, metric_value, threshold_value)
      SELECT 'payment_failure_rate', 'critical',
        format('Payment failure rate %s%% over last hour (%s failed / %s total)',
          ROUND(v_payment_failure_rate * 100, 1), v_payment_failed, v_payment_total),
        v_payment_failure_rate, 0.20
      WHERE NOT EXISTS (
        SELECT 1 FROM public.system_alerts
        WHERE alert_type = 'payment_failure_rate' AND resolved_at IS NULL
      )
      RETURNING * INTO v_row;
      IF v_row.id IS NOT NULL THEN RETURN NEXT v_row; END IF;
    END IF;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.check_system_alerts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_system_alerts() TO service_role;

-- Admin-facing read of current + historical alerts (mirrors the dashboard
-- RPC pattern already established).
CREATE OR REPLACE FUNCTION public.get_system_alerts()
RETURNS SETOF public.system_alerts
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY SELECT * FROM public.system_alerts ORDER BY triggered_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_system_alerts() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_system_alerts() FROM anon;
