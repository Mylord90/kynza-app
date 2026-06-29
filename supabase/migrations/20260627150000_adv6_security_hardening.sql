-- ================================================================
-- ADV.6 — Security hardening audit findings.
-- ================================================================

-- 1. Defense-in-depth: these two RPCs already self-guard via
-- has_role(auth.uid(), ...) (an anon caller's auth.uid() is NULL, so the
-- guard already raises 'forbidden' for them) — but unlike every RPC added
-- since Phase 3B, they never got an explicit REVOKE FROM anon. Postgres
-- grants EXECUTE to PUBLIC by default on function creation, so closing
-- this brings them in line with add_loyalty_stamp/mark_invoice_paid/etc.
REVOKE EXECUTE ON FUNCTION public.check_and_increment_promo_quota(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_staff_week_rank(UUID) FROM anon;

-- 2. Missing indexes on foreign-key columns that are actually queried by
-- the app (myStaffProfileProvider filters staff_profiles by user_id on
-- every staff session; v_top_services joins bookings to services; etc.)
-- — found by cross-referencing every `REFERENCES` column against existing
-- indexes across all migrations.
CREATE INDEX IF NOT EXISTS idx_staff_profiles_user
  ON public.staff_profiles(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_bookings_service
  ON public.bookings(service_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_services_staff
  ON public.staff_services(staff_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_services_service
  ON public.staff_services(service_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_client_contacts_owner
  ON public.client_contacts(owner_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_client_contacts_client_user
  ON public.client_contacts(client_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_referrals_referrer
  ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred
  ON public.referrals(referred_id);
CREATE INDEX IF NOT EXISTS idx_referrals_salon
  ON public.referrals(salon_id);
CREATE INDEX IF NOT EXISTS idx_review_media_review
  ON public.review_media(review_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_loyalty_qr_tokens_salon
  ON public.loyalty_qr_tokens(salon_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_qr_tokens_client
  ON public.loyalty_qr_tokens(client_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_stamp_logs_salon
  ON public.loyalty_stamp_logs(salon_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_stamp_logs_client
  ON public.loyalty_stamp_logs(client_id);
CREATE INDEX IF NOT EXISTS idx_promotions_service
  ON public.promotions(service_id) WHERE deleted_at IS NULL;

-- 3. Rate limiting backing store — same upsert-a-window-counter shape as
-- notification_quota, generalized to an arbitrary string key (Edge
-- Functions key by "<function-name>:<caller-id>"). service_role only —
-- Edge Functions are the only caller, never the Flutter app directly.
CREATE TABLE IF NOT EXISTS public.rate_limit_buckets (
  key TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (key, window_start)
);

CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_key TEXT, p_max INT, p_window_seconds INT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_window_start TIMESTAMPTZ :=
    to_timestamp(floor(extract(epoch FROM NOW()) / p_window_seconds) * p_window_seconds);
  v_count INT;
BEGIN
  INSERT INTO public.rate_limit_buckets (key, window_start, count)
  VALUES (p_key, v_window_start, 1)
  ON CONFLICT (key, window_start)
  DO UPDATE SET count = public.rate_limit_buckets.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= p_max;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.check_rate_limit(TEXT, INT, INT) FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(TEXT, INT, INT) TO service_role;

-- No RLS policies needed — service_role bypasses RLS entirely, and no
-- other role can ever read/write this table (no GRANT to authenticated).
ALTER TABLE public.rate_limit_buckets ENABLE ROW LEVEL SECURITY;