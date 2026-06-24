-- ================================================================
-- KYNZA — Migration 020 — Phase 2.2 / Module 2 — Dashboard analytics views
-- security_invoker = true on every view: each view runs with the
-- privileges of the querying role, so the existing bookings/staff_profiles
-- RLS policies still apply underneath (a Staff session only ever sees
-- their own practitioner_id rows aggregated here — R11/R07 already
-- enforced at the table level, these views add no privilege escalation).
-- ================================================================

CREATE OR REPLACE VIEW public.v_salon_kpis
WITH (security_invoker = true) AS
SELECT
  b.salon_id,
  DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura') AS day,
  COUNT(*) FILTER (WHERE b.status NOT IN ('cancelled', 'no_show')) AS bookings_total,
  COUNT(*) FILTER (WHERE b.status = 'completed') AS bookings_completed,
  COUNT(*) FILTER (WHERE b.status = 'cancelled') AS bookings_cancelled,
  COUNT(*) FILTER (WHERE b.status = 'no_show') AS bookings_no_show,
  COALESCE(SUM(b.amount_bif) FILTER (WHERE b.payment_status = 'completed'), 0) AS revenue_bif,
  CASE WHEN COUNT(*) > 0
    THEN ROUND(COUNT(*) FILTER (WHERE b.status = 'no_show')::numeric / COUNT(*) * 100, 1)
    ELSE 0
  END AS no_show_rate,
  CASE WHEN COUNT(*) > 0
    THEN ROUND(COUNT(*) FILTER (WHERE b.status = 'cancelled')::numeric / COUNT(*) * 100, 1)
    ELSE 0
  END AS cancellation_rate
FROM public.bookings b
WHERE b.deleted_at IS NULL
GROUP BY b.salon_id, DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura');

CREATE OR REPLACE VIEW public.v_top_services
WITH (security_invoker = true) AS
SELECT
  b.salon_id,
  b.service_id,
  s.name AS service_name,
  s.price_bif,
  COUNT(*) AS booking_count,
  COALESCE(SUM(b.amount_bif) FILTER (WHERE b.payment_status = 'completed'), 0) AS total_revenue_bif,
  DATE_TRUNC('month', b.created_at) AS month
FROM public.bookings b
JOIN public.services s ON s.id = b.service_id
WHERE b.deleted_at IS NULL AND b.status NOT IN ('cancelled', 'no_show')
GROUP BY b.salon_id, b.service_id, s.name, s.price_bif, DATE_TRUNC('month', b.created_at);

CREATE OR REPLACE VIEW public.v_top_staff
WITH (security_invoker = true) AS
SELECT
  sp.salon_id,
  sp.id AS staff_id,
  sp.display_name,
  sp.avatar_url,
  COUNT(b.id) AS booking_count,
  COALESCE(SUM(b.amount_bif) FILTER (WHERE b.payment_status = 'completed'), 0) AS revenue_bif,
  DATE_TRUNC('week', COALESCE(b.start_time, NOW())) AS week_start
FROM public.staff_profiles sp
LEFT JOIN public.bookings b
  ON b.practitioner_id = sp.id
  AND b.deleted_at IS NULL
  AND b.status NOT IN ('cancelled', 'no_show')
WHERE sp.deleted_at IS NULL
GROUP BY sp.salon_id, sp.id, sp.display_name, sp.avatar_url, DATE_TRUNC('week', COALESCE(b.start_time, NOW()));

CREATE OR REPLACE VIEW public.v_occupancy
WITH (security_invoker = true) AS
SELECT
  b.salon_id,
  b.practitioner_id,
  DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura') AS day,
  COUNT(*) AS booked_slots,
  -- Estimated max slots: 8h day at ~30min/slot = 16 max (matches the
  -- existing fill-rate heuristic in booking_providers.dart's SalonKpis).
  ROUND(COUNT(*)::numeric / 16 * 100, 1) AS occupancy_pct
FROM public.bookings b
WHERE b.deleted_at IS NULL AND b.status NOT IN ('cancelled', 'no_show')
GROUP BY b.salon_id, b.practitioner_id, DATE(b.start_time AT TIME ZONE 'Africa/Bujumbura');

GRANT SELECT ON public.v_salon_kpis TO authenticated;
GRANT SELECT ON public.v_top_services TO authenticated;
GRANT SELECT ON public.v_top_staff TO authenticated;
GRANT SELECT ON public.v_occupancy TO authenticated;
