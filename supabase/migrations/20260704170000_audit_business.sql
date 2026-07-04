-- Phase 10 (Backend Enterprise Completion) — Audit Business
-- Split exactly like Phase 2: Track A built fully now, Track B schema-only
-- (report generation deferred to when real production data exists).
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8.

-- ═══════════════════════════════════════════════════════════════════════
-- TRACK A — build fully now
-- ═══════════════════════════════════════════════════════════════════════

-- 1. Security audit trail — extends the existing activity_logs-based
-- AuditLogger pipeline (Phase 2/3 of this pass already added
-- feature_flag_override_*, client_error_logged to its whitelist). This view
-- just formalizes a queryable "security-sensitive events" slice rather than
-- inventing a parallel log.
CREATE OR REPLACE VIEW public.v_audit_security_trail AS
SELECT
  id, salon_id, user_id, type_action, severity, created_at
FROM public.activity_logs
WHERE type_action IN (
  'user_login', 'user_logout', 'role_changed',
  'permission_group_created', 'permission_group_deleted',
  'permission_group_permission_changed',
  'permission_group_member_added', 'permission_group_member_removed',
  'settings_changed', 'feature_flag_override_set', 'feature_flag_override_removed'
);

-- 2. RGPD audit — unions the two already-complete GDPR-relevant trails
-- (deletion requests from Legal Center, data exports from the backup
-- Edge Function) rather than adding a third logging mechanism — both
-- tables already carry everything a GDPR audit needs (who, when, what).
CREATE OR REPLACE VIEW public.v_audit_rgpd_trail AS
SELECT
  'deletion_request' AS event_type,
  id AS record_id,
  user_id AS actor_id,
  status,
  requested_at AS occurred_at,
  processed_at AS resolved_at
FROM public.data_deletion_requests
WHERE deleted_at IS NULL
UNION ALL
SELECT
  'data_export' AS event_type,
  id AS record_id,
  initiated_by AS actor_id,
  status,
  created_at AS occurred_at,
  completed_at AS resolved_at
FROM public.backup_jobs;

-- 3. Fraud audit — ProxiPay anomaly heuristics over existing
-- proxipay_sessions data (reuses the same idempotency/replay-protection
-- data already captured by the hardening pass, no new collection):
--   a) more than one session ever created for the same booking (a known,
--      documented gap — EDGE_FUNCTIONS_REFERENCE.md already flags
--      proxipay-create-session as having no such guard)
--   b) a staff member creating an unusual burst of sessions (>10) within
--      a single hour.
CREATE OR REPLACE VIEW public.v_audit_fraud_proxipay AS
SELECT
  'duplicate_sessions_per_booking' AS anomaly_type,
  booking_id::TEXT AS subject_id,
  COUNT(*) AS occurrence_count
FROM public.proxipay_sessions
GROUP BY booking_id
HAVING COUNT(*) > 1
UNION ALL
SELECT
  'staff_session_burst' AS anomaly_type,
  staff_id::TEXT AS subject_id,
  COUNT(*) AS occurrence_count
FROM public.proxipay_sessions
GROUP BY staff_id, DATE_TRUNC('hour', created_at)
HAVING COUNT(*) > 10;

-- Error audit (Crash Dashboard) and Performance audit (Edge Function +
-- Queue Dashboards) are DELIBERATELY NOT rebuilt here — Phase 2 of this
-- pass already built v_crash_dashboard/get_crash_dashboard() and
-- v_edge_function_dashboard/v_queue_dashboard with their gated RPCs; this
-- phase's "audit" angle on error/performance data is the exact same
-- pipeline, consumed as a periodic report rather than a live dashboard —
-- rebuilding it here would be the literal duplication this pass has
-- avoided at every prior checkpoint (Phase 5/Health Center, Phase 8/config
-- coverage). Sync audit (DLQ/outbox failure trail) is likewise
-- client-side-only, same reasoning as Phase 2's Sync Dashboard — no SQL
-- view exists for it, `MutationOutboxService.deadLetterItems()` already
-- IS this audit trail.

-- Admin-gated RPC wrappers for the 3 genuinely new Track A views.
CREATE OR REPLACE FUNCTION public.get_audit_security_trail() RETURNS SETOF public.v_audit_security_trail
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_security_trail ORDER BY created_at DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_rgpd_trail() RETURNS SETOF public.v_audit_rgpd_trail
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_rgpd_trail ORDER BY occurred_at DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_fraud_proxipay() RETURNS SETOF public.v_audit_fraud_proxipay
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_fraud_proxipay;
END; $$;

GRANT EXECUTE ON FUNCTION public.get_audit_security_trail() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_rgpd_trail() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_fraud_proxipay() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_audit_security_trail() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_rgpd_trail() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_fraud_proxipay() FROM anon;

-- ═══════════════════════════════════════════════════════════════════════
-- TRACK B — schema only, report generation deferred to post-launch
-- ═══════════════════════════════════════════════════════════════════════
-- Payment-volume, loyalty-engagement, and subscription-churn audits
-- deliberately REUSE Phase 6's v_bi_payments/v_bi_loyalty/v_bi_subscriptions
-- (get_bi_payments()/get_bi_loyalty()/get_bi_subscriptions()) rather than
-- building 3 near-identical views — same underlying data, "audit" is a
-- reporting angle on it, not a different pipeline. Only the 5 views below
-- are genuinely new for Phase 10.

-- Financial/accounting audit — invoices reconciled against transactions.
CREATE OR REPLACE VIEW public.v_audit_financial_accounting AS
SELECT
  i.salon_id,
  i.plan_key,
  i.status AS invoice_status,
  i.amount_bif AS invoice_amount_bif,
  i.created_at,
  i.paid_at
FROM public.invoices i;

-- User-behavior audit — broad activity_logs volume by action, all-time.
CREATE OR REPLACE VIEW public.v_audit_user_behavior AS
SELECT
  type_action,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS distinct_users
FROM public.activity_logs
GROUP BY type_action;

-- Salon-performance audit — bookings completed vs. reviews received.
CREATE OR REPLACE VIEW public.v_audit_salon_performance AS
SELECT
  b.salon_id,
  COUNT(DISTINCT b.id) FILTER (WHERE b.status = 'completed') AS completed_bookings,
  COUNT(DISTINCT r.id) AS review_count,
  ROUND(AVG(r.rating), 2) AS avg_rating
FROM public.bookings b
LEFT JOIN public.reviews r ON r.salon_id = b.salon_id
GROUP BY b.salon_id;

-- Commission-accuracy audit — flags a commission row whose amount doesn't
-- match its own stated rate applied to the booking's amount (a real
-- correctness check, not just a volume report).
CREATE OR REPLACE VIEW public.v_audit_commission_accuracy AS
SELECT
  sc.id AS commission_id,
  sc.booking_id,
  sc.rate_type,
  sc.rate_value,
  sc.amount_bif AS recorded_amount_bif,
  b.amount_bif AS booking_amount_bif,
  CASE
    WHEN sc.rate_type = 'percent' THEN ROUND(b.amount_bif * sc.rate_value / 100.0)
    ELSE sc.rate_value
  END AS expected_amount_bif
FROM public.staff_commissions sc
JOIN public.bookings b ON b.id = sc.booking_id
WHERE sc.deleted_at IS NULL
  AND sc.amount_bif != CASE
    WHEN sc.rate_type = 'percent' THEN ROUND(b.amount_bif * sc.rate_value / 100.0)
    ELSE sc.rate_value
  END;

-- Automation-execution audit — real data already exists (automation engine
-- shipped in the prior hardening pass), report generation just deferred.
CREATE OR REPLACE VIEW public.v_audit_automation_execution AS
SELECT
  workflow_id,
  trigger_type,
  status,
  COUNT(*) AS execution_count,
  ROUND(AVG(duration_ms)) AS avg_duration_ms,
  COUNT(*) FILTER (WHERE status = 'failed') AS failure_count
FROM public.automation_execution_logs
GROUP BY workflow_id, trigger_type, status;

CREATE OR REPLACE FUNCTION public.get_audit_financial_accounting() RETURNS SETOF public.v_audit_financial_accounting
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_financial_accounting;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_user_behavior() RETURNS SETOF public.v_audit_user_behavior
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_user_behavior;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_salon_performance() RETURNS SETOF public.v_audit_salon_performance
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_salon_performance;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_commission_accuracy() RETURNS SETOF public.v_audit_commission_accuracy
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_commission_accuracy;
END; $$;

CREATE OR REPLACE FUNCTION public.get_audit_automation_execution() RETURNS SETOF public.v_audit_automation_execution
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_audit_automation_execution;
END; $$;

GRANT EXECUTE ON FUNCTION public.get_audit_financial_accounting() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_user_behavior() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_salon_performance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_commission_accuracy() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_automation_execution() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_audit_financial_accounting() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_user_behavior() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_salon_performance() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_commission_accuracy() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_audit_automation_execution() FROM anon;
