-- Phase 6 (Backend Enterprise Completion) — Business Observability
-- TRACK B — schema/pipeline only, dashboards intentionally deferred to
-- post-launch. DRAFT — reviewed but NOT applied to the remote project.
--
-- Every view below is built over EXISTING tables (bookings, transactions,
-- salons, subscription_plans, invoices, staff_commissions, referrals,
-- loyalty_cards, owner_journey_progress) — no new raw data collection, per
-- the brief's own instruction, since KYNZA doesn't yet generate the volume
-- that would justify a new event-tracking pipeline. 13 views consolidate
-- the brief's ~21 named metrics (grouped where multiple named metrics are
-- really the same underlying aggregate, documented in
-- docs/backend-completion/PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md rather
-- than silently dropped). All admin/cross-tenant — gated the same way as
-- Phase 2's dashboards (SECURITY DEFINER RPC + has_system_admin() check,
-- no view granted directly to authenticated/anon).

-- 1. Revenue / ARPU / revenue-forecast-inputs
CREATE OR REPLACE VIEW public.v_bi_revenue AS
SELECT
  DATE_TRUNC('month', confirmed_at) AS month,
  COUNT(*) AS completed_transactions,
  SUM(amount_bif) AS revenue_bif,
  ROUND(SUM(amount_bif)::NUMERIC / NULLIF(COUNT(DISTINCT salon_id), 0), 2) AS arpu_bif
FROM public.transactions
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', confirmed_at);

-- 2. Salons active/churned + growth
CREATE OR REPLACE VIEW public.v_bi_salons AS
SELECT
  DATE_TRUNC('month', created_at) AS signup_month,
  COUNT(*) AS new_salons,
  COUNT(*) FILTER (WHERE plan_status = 'active') AS active_salons,
  COUNT(*) FILTER (WHERE plan_status = 'expired') AS churned_salons_point_in_time
FROM public.salons
WHERE deleted_at IS NULL
GROUP BY DATE_TRUNC('month', created_at);

-- 3. Staff
CREATE OR REPLACE VIEW public.v_bi_staff AS
SELECT
  salon_id,
  COUNT(*) AS total_staff,
  COUNT(*) FILTER (WHERE is_active = true) AS active_staff
FROM public.staff_profiles
WHERE deleted_at IS NULL
GROUP BY salon_id;

-- 4. Clients + retention (>1 completed booking in the last 90 days)
CREATE OR REPLACE VIEW public.v_bi_clients AS
SELECT
  salon_id,
  COUNT(DISTINCT client_id) AS unique_clients,
  COUNT(DISTINCT client_id) FILTER (
    WHERE client_id IN (
      SELECT client_id FROM public.bookings b2
      WHERE b2.salon_id = b.salon_id AND b2.status = 'completed'
        AND b2.start_time > now() - INTERVAL '90 days'
      GROUP BY client_id HAVING COUNT(*) > 1
    )
  ) AS retained_clients_90d
FROM public.bookings b
WHERE status = 'completed'
GROUP BY salon_id;

-- 5. Subscriptions + MRR + ARR + churn (point-in-time proxy — see doc)
CREATE OR REPLACE VIEW public.v_bi_subscriptions AS
SELECT
  sp.key AS plan_key,
  COUNT(s.id) AS salon_count,
  COUNT(s.id) FILTER (WHERE s.plan_status = 'active') AS active_count,
  COUNT(s.id) FILTER (WHERE s.plan_status = 'expired') AS churned_count_point_in_time,
  sp.price_bif * COUNT(s.id) FILTER (WHERE s.plan_status = 'active') AS mrr_bif,
  sp.price_bif * COUNT(s.id) FILTER (WHERE s.plan_status = 'active') * 12 AS arr_bif
FROM public.subscription_plans sp
LEFT JOIN public.salons s ON s.plan = sp.key AND s.deleted_at IS NULL
GROUP BY sp.key, sp.price_bif;

-- 6. Commissions
CREATE OR REPLACE VIEW public.v_bi_commissions AS
SELECT
  DATE_TRUNC('month', created_at) AS month,
  status,
  COUNT(*) AS commission_count,
  SUM(amount_bif) AS total_amount_bif
FROM public.staff_commissions
WHERE deleted_at IS NULL
GROUP BY DATE_TRUNC('month', created_at), status;

-- 7. Bookings + cancellations
CREATE OR REPLACE VIEW public.v_bi_bookings AS
SELECT
  DATE_TRUNC('month', start_time) AS month,
  status,
  COUNT(*) AS booking_count,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE status IN ('cancelled', 'no_show'))
      / NULLIF(COUNT(*), 0),
    2
  ) AS cancellation_rate_percent
FROM public.bookings
GROUP BY DATE_TRUNC('month', start_time), status;

-- 8. Payments
CREATE OR REPLACE VIEW public.v_bi_payments AS
SELECT
  DATE_TRUNC('month', initiated_at) AS month,
  status,
  method,
  COUNT(*) AS transaction_count,
  SUM(amount_bif) AS amount_bif
FROM public.transactions
GROUP BY DATE_TRUNC('month', initiated_at), status, method;

-- 9. Loyalty engagement
CREATE OR REPLACE VIEW public.v_bi_loyalty AS
SELECT
  salon_id,
  COUNT(*) AS total_cards,
  ROUND(AVG(stamps_count), 2) AS avg_current_stamps,
  ROUND(AVG(total_redeemed), 2) AS avg_redemptions,
  SUM(total_redeemed) AS total_redemptions
FROM public.loyalty_cards
WHERE deleted_at IS NULL
GROUP BY salon_id;

-- 10. Referrals + conversion funnel
CREATE OR REPLACE VIEW public.v_bi_referrals AS
SELECT
  status,
  COUNT(*) AS referral_count,
  COUNT(*) FILTER (WHERE reward_granted) AS rewarded_count
FROM public.referrals
GROUP BY status;

-- 11. Activation (owner completes first booking — real signal, already tracked)
CREATE OR REPLACE VIEW public.v_bi_activation AS
SELECT
  COUNT(*) AS total_salons_tracked,
  COUNT(*) FILTER (WHERE step_first_booking_done) AS activated_salons,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE step_first_booking_done) / NULLIF(COUNT(*), 0),
    2
  ) AS activation_rate_percent
FROM public.owner_journey_progress;

-- 12. LTV per client
CREATE OR REPLACE VIEW public.v_bi_ltv AS
SELECT
  b.client_id,
  b.salon_id,
  SUM(t.amount_bif) AS lifetime_value_bif,
  COUNT(DISTINCT b.id) AS lifetime_bookings
FROM public.transactions t
JOIN public.bookings b ON b.id = t.booking_id
WHERE t.status = 'completed'
GROUP BY b.client_id, b.salon_id;

-- 13. Conversion — NO real data source exists (no visit/funnel-event
-- tracking table anywhere in this codebase). Rather than fabricate a
-- number, this view structurally returns zero rows always — a real
-- conversion-funnel metric needs a client-side event pipeline that does
-- not exist yet and is explicitly out of this phase's "no new raw data
-- collection" constraint. Documented, not hidden.
CREATE OR REPLACE VIEW public.v_bi_conversion AS
SELECT
  NULL::TIMESTAMPTZ AS month,
  NULL::BIGINT AS visits,
  NULL::BIGINT AS bookings_started,
  NULL::BIGINT AS bookings_completed
WHERE false;

-- ─── Admin-gated RPC wrappers (same shape as Phase 2's dashboards) ─────────

CREATE OR REPLACE FUNCTION public.get_bi_revenue() RETURNS SETOF public.v_bi_revenue
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_revenue;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_salons() RETURNS SETOF public.v_bi_salons
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_salons;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_staff() RETURNS SETOF public.v_bi_staff
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_staff;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_clients() RETURNS SETOF public.v_bi_clients
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_clients;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_subscriptions() RETURNS SETOF public.v_bi_subscriptions
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_subscriptions;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_commissions() RETURNS SETOF public.v_bi_commissions
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_commissions;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_bookings() RETURNS SETOF public.v_bi_bookings
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_bookings;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_payments() RETURNS SETOF public.v_bi_payments
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_payments;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_loyalty() RETURNS SETOF public.v_bi_loyalty
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_loyalty;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_referrals() RETURNS SETOF public.v_bi_referrals
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_referrals;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_activation() RETURNS SETOF public.v_bi_activation
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_activation;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_ltv() RETURNS SETOF public.v_bi_ltv
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_ltv;
END; $$;

CREATE OR REPLACE FUNCTION public.get_bi_conversion() RETURNS SETOF public.v_bi_conversion
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY SELECT * FROM public.v_bi_conversion;
END; $$;

GRANT EXECUTE ON FUNCTION public.get_bi_revenue() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_salons() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_clients() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_subscriptions() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_commissions() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_bookings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_payments() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_loyalty() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_referrals() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_activation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_ltv() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bi_conversion() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_bi_revenue() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_salons() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_staff() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_clients() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_subscriptions() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_commissions() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_bookings() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_payments() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_loyalty() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_referrals() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_activation() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_ltv() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_bi_conversion() FROM anon;
