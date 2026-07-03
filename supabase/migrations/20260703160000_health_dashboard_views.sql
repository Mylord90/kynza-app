-- DRAFT — reviewed but NOT applied to the remote project as part of the
-- Enterprise Hardening & Production Readiness pass, Phase 4 (Observability,
-- Monitoring & Disaster Recovery). This repo has no local Supabase/Docker
-- stack; `supabase db push` hits the live project (hhdkjfpgaklhrhfoxlhj)
-- directly. Apply manually after review, per Rule 8.
--
-- Two of the 5 metrics named in the Health Dashboard spec
-- (docs/OBSERVABILITY_MONITORING.md §3) as genuine new SQL views:
-- payment success rate and notification delivery rate. The other 3 are
-- deliberately NOT duplicated here:
--   - audit log volume:   already covered by mv_audit_stats
--                         (20260629110000_audit_enterprise.sql)
--   - revenue/bookings:   already covered by mv_daily_revenue
--                         (20260630100100_phase3_mv_revenue.sql)
--   - API latency:        Firebase Performance's automatic network traces
--                         already capture this client-side per request —
--                         a server-side SQL view can't see client-observed
--                         latency at all, so one was never designed here.
--   - sync queue depth:   the Hive-based legal-acceptance outbox is
--                         entirely client-local storage; there is nothing
--                         in Postgres to build a view over. See
--                         docs/OBSERVABILITY_MONITORING.md §2 for how this
--                         is actually observed instead (Crashlytics custom
--                         keys, not a SQL view).
--
-- security_invoker = true on both views, matching the existing
-- v_salon_kpis/v_top_services pattern (20260624070000_analytics_views.sql)
-- — each view runs with the querying role's own privileges, so the
-- existing transactions/notification_logs RLS policies (owner-only for
-- transactions; owner/manager salon-wide for notification_logs) still
-- apply underneath. No privilege escalation.

CREATE OR REPLACE VIEW public.v_payment_success_rate
WITH (security_invoker = true) AS
SELECT
  t.salon_id,
  DATE(t.created_at AT TIME ZONE 'Africa/Bujumbura') AS day,
  t.method,
  COUNT(*) AS attempts_total,
  COUNT(*) FILTER (WHERE t.status = 'completed') AS attempts_completed,
  COUNT(*) FILTER (WHERE t.status = 'failed') AS attempts_failed,
  COUNT(*) FILTER (WHERE t.status = 'expired') AS attempts_expired,
  CASE WHEN COUNT(*) > 0
    THEN ROUND(COUNT(*) FILTER (WHERE t.status = 'completed')::numeric / COUNT(*) * 100, 1)
    ELSE 0
  END AS success_rate_pct
FROM public.transactions t
WHERE t.deleted_at IS NULL
GROUP BY t.salon_id, DATE(t.created_at AT TIME ZONE 'Africa/Bujumbura'), t.method;

CREATE OR REPLACE VIEW public.v_notification_delivery_rate
WITH (security_invoker = true) AS
SELECT
  n.salon_id,
  DATE(n.created_at AT TIME ZONE 'Africa/Bujumbura') AS day,
  n.channel,
  COUNT(*) AS sent_total,
  COUNT(*) FILTER (WHERE n.delivered) AS delivered_total,
  CASE WHEN COUNT(*) > 0
    THEN ROUND(COUNT(*) FILTER (WHERE n.delivered)::numeric / COUNT(*) * 100, 1)
    ELSE 0
  END AS delivery_rate_pct
FROM public.notification_logs n
WHERE n.deleted_at IS NULL AND n.salon_id IS NOT NULL
GROUP BY n.salon_id, DATE(n.created_at AT TIME ZONE 'Africa/Bujumbura'), n.channel;
