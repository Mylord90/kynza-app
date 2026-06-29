-- ================================================================
-- PHASE 4 — Owner Dashboard Enterprise: client LTV, staff monthly
-- performance, churn risk, cohort retention.
-- security_invoker = true on every view, same as 20260624070000 —
-- each view runs with the privileges of the querying role, so existing
-- bookings/users RLS still applies underneath.
-- ================================================================

CREATE OR REPLACE VIEW public.v_client_ltv
WITH (security_invoker = true) AS
SELECT
  b.salon_id,
  b.client_id,
  u.full_name AS client_name,
  COUNT(*) AS visit_count,
  COALESCE(SUM(b.amount_bif) FILTER (WHERE b.payment_status = 'completed'), 0) AS total_spent_bif,
  MIN(b.start_time) AS first_visit_at,
  MAX(b.start_time) AS last_visit_at
FROM public.bookings b
JOIN public.users u ON u.id = b.client_id
WHERE b.deleted_at IS NULL AND b.status NOT IN ('cancelled', 'no_show')
GROUP BY b.salon_id, b.client_id, u.full_name;

CREATE OR REPLACE VIEW public.v_staff_monthly_performance
WITH (security_invoker = true) AS
SELECT
  sp.salon_id,
  sp.id AS staff_id,
  sp.display_name,
  sp.avatar_url,
  DATE_TRUNC('month', COALESCE(b.start_time, NOW())) AS month,
  COUNT(*) FILTER (WHERE b.status = 'completed') AS completions,
  COUNT(*) FILTER (WHERE b.status = 'no_show') AS no_shows,
  COUNT(*) FILTER (WHERE b.status = 'cancelled') AS cancellations,
  COALESCE(SUM(b.amount_bif) FILTER (WHERE b.payment_status = 'completed'), 0) AS revenue_bif,
  ROUND(AVG(r.rating), 1) AS avg_rating
FROM public.staff_profiles sp
LEFT JOIN public.bookings b
  ON b.practitioner_id = sp.id AND b.deleted_at IS NULL
LEFT JOIN public.reviews r
  ON r.booking_id = b.id AND r.deleted_at IS NULL
WHERE sp.deleted_at IS NULL
GROUP BY sp.salon_id, sp.id, sp.display_name, sp.avatar_url,
  DATE_TRUNC('month', COALESCE(b.start_time, NOW()));

-- Risk thresholds are heuristic (no per-salon visit-frequency baseline
-- yet) — high >=60d, medium 30-59d, low 15-29d since last completed
-- visit; clients under 15d aren't surfaced as a risk at all.
CREATE OR REPLACE VIEW public.v_churn_risk
WITH (security_invoker = true) AS
SELECT
  salon_id,
  client_id,
  client_name,
  last_visit_at,
  EXTRACT(DAY FROM NOW() - last_visit_at)::int AS days_since_last_visit,
  CASE
    WHEN EXTRACT(DAY FROM NOW() - last_visit_at) >= 60 THEN 'high'
    WHEN EXTRACT(DAY FROM NOW() - last_visit_at) >= 30 THEN 'medium'
    ELSE 'low'
  END AS risk_level
FROM public.v_client_ltv
WHERE last_visit_at IS NOT NULL
  AND EXTRACT(DAY FROM NOW() - last_visit_at) >= 15;

GRANT SELECT ON public.v_client_ltv TO authenticated;
GRANT SELECT ON public.v_staff_monthly_performance TO authenticated;
GRANT SELECT ON public.v_churn_risk TO authenticated;

-- Cohort = month of a client's first completed visit at this salon;
-- month_offset 0-3 tracks what fraction of that cohort returned in the
-- following 3 months. SECURITY INVOKER — relies on the caller's existing
-- SELECT access to bookings/users (same as the views above), no
-- privilege escalation.
CREATE OR REPLACE FUNCTION public.get_cohort_retention(p_salon_id UUID)
RETURNS TABLE(cohort_month DATE, month_offset INT, cohort_size INT, retained_count INT)
LANGUAGE sql SECURITY INVOKER STABLE SET search_path = public, pg_temp AS $$
  WITH first_visit AS (
    SELECT client_id, DATE_TRUNC('month', MIN(start_time))::date AS cohort_month
    FROM public.bookings
    WHERE salon_id = p_salon_id AND deleted_at IS NULL
      AND status NOT IN ('cancelled', 'no_show')
    GROUP BY client_id
  ),
  visits AS (
    SELECT client_id, DATE_TRUNC('month', start_time)::date AS visit_month
    FROM public.bookings
    WHERE salon_id = p_salon_id AND deleted_at IS NULL
      AND status NOT IN ('cancelled', 'no_show')
    GROUP BY client_id, DATE_TRUNC('month', start_time)
  ),
  joined AS (
    SELECT
      fv.cohort_month,
      fv.client_id,
      (DATE_PART('year', v.visit_month) - DATE_PART('year', fv.cohort_month)) * 12
        + (DATE_PART('month', v.visit_month) - DATE_PART('month', fv.cohort_month)) AS month_offset
    FROM first_visit fv
    JOIN visits v ON v.client_id = fv.client_id AND v.visit_month >= fv.cohort_month
  )
  SELECT
    j.cohort_month,
    j.month_offset::int,
    (SELECT COUNT(*) FROM first_visit f2 WHERE f2.cohort_month = j.cohort_month)::int AS cohort_size,
    COUNT(DISTINCT j.client_id)::int AS retained_count
  FROM joined j
  WHERE j.month_offset BETWEEN 0 AND 3
  GROUP BY j.cohort_month, j.month_offset
  ORDER BY j.cohort_month, j.month_offset;
$$;
REVOKE EXECUTE ON FUNCTION public.get_cohort_retention(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_cohort_retention(UUID) TO authenticated;