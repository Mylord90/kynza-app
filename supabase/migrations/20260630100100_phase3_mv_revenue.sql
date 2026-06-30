-- ================================================================
-- PHASE 3 — Enterprise Data Platform
-- Sub-migration 2/4: mv_daily_revenue + nightly refresh
--
-- WHY a materialized view alongside the existing v_salon_kpis view:
--
-- v_salon_kpis (security_invoker, regular view) is correct for the
-- live dashboard: RLS applies to every SELECT, giving per-session
-- tenant isolation without any extra filtering.
--
-- mv_daily_revenue is a pre-aggregated snapshot for:
--   • The automation engine's `update_stats` action (service_role)
--   • Owner-triggered data exports (via Edge Function, service_role)
--   • Any future heavy reporting that can tolerate ~24h staleness
--
-- MV has no RLS (Postgres doesn't support RLS on MVs).
-- Access is therefore restricted to service_role only — no grant to
-- authenticated or anon.  Per-session dashboards must keep using
-- v_salon_kpis.  A v_mv_daily_revenue thin view is exposed to
-- authenticated users with an inline salon_id filter (equivalent
-- to the RLS guard on the underlying bookings table).
-- ================================================================

-- ── 1. Materialized view ──────────────────────────────────────────
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_daily_revenue AS
SELECT
  b.salon_id,
  DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura') AS day,
  COUNT(*)                                                    AS bookings_total,
  COUNT(*) FILTER (WHERE b.status = 'completed')             AS bookings_completed,
  COUNT(*) FILTER (WHERE b.status = 'no_show')               AS bookings_no_show,
  COUNT(*) FILTER (WHERE b.status = 'cancelled')             AS bookings_cancelled,
  COALESCE(SUM(b.amount_bif) FILTER (
    WHERE b.payment_status = 'completed'
  ), 0)                                                       AS revenue_bif
FROM public.bookings b
WHERE b.deleted_at IS NULL
GROUP BY b.salon_id, DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura');

-- Unique index required for REFRESH CONCURRENTLY (no table lock)
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_daily_revenue_pk
  ON public.mv_daily_revenue (salon_id, day);

-- No GRANT to authenticated/anon — service_role only.

-- ── 2. Tenant-filtered view for authenticated users ───────────────
-- Thin wrapper that re-applies the salon_id isolation the MV lost.
-- SECURITY INVOKER is irrelevant here (the MV has no RLS), but we set
-- it to document intent: the view itself adds no privilege escalation.
CREATE OR REPLACE VIEW public.v_mv_daily_revenue
WITH (security_invoker = false) AS
SELECT mvr.*
FROM public.mv_daily_revenue mvr
WHERE mvr.salon_id = (
  SELECT u.salon_id FROM public.users u
  WHERE u.id = auth.uid()
  LIMIT 1
);

GRANT SELECT ON public.v_mv_daily_revenue TO authenticated;

-- ── 3. pg_cron: nightly refresh at midnight UTC (2h Bujumbura) ────
-- Uses CONCURRENTLY so the MV stays queryable during the refresh.
-- The unique index above is required for CONCURRENTLY to work.
SELECT cron.schedule(
  'refresh-mv-daily-revenue',
  '0 0 * * *',
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_daily_revenue$$
);