-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.4 — Centre de Configuration
--
-- `currency` deliberately dropped from the brief's column list — salons
-- already has a NOT NULL `currency` column (foundation migration). A
-- second `salon_settings.currency` would be a second source of truth for
-- the same fact; if the two ever diverged, nothing says which one the
-- app should trust. `timezone` is kept (salons has none) — Burundi-only
-- in V1 but consistent with the existing multi-country-ready columns
-- (`salons.country_code`/`currency`) the rest of the schema already has.
-- ================================================================

CREATE TABLE IF NOT EXISTS public.salon_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL UNIQUE REFERENCES public.salons(id) ON DELETE CASCADE,
  -- Booking
  booking_advance_days INTEGER NOT NULL DEFAULT 30,
  booking_slot_duration_minutes INTEGER NOT NULL DEFAULT 30,
  booking_cancellation_hours INTEGER NOT NULL DEFAULT 24,
  booking_requires_confirmation BOOLEAN NOT NULL DEFAULT TRUE,
  booking_allow_walkin BOOLEAN NOT NULL DEFAULT TRUE,
  booking_max_per_client_per_day INTEGER NOT NULL DEFAULT 3,
  -- Notifications (salon-wide channel policy — distinct from the
  -- per-user public.notification_preferences table: this is "does this
  -- salon use channel X at all", not "does this user want it")
  notif_sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  notif_whatsapp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  notif_push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  notif_reminder_hours_before INTEGER NOT NULL DEFAULT 24,
  notif_reminder_hours_before_2 INTEGER NOT NULL DEFAULT 1,
  -- Marketing
  marketing_auto_review_request BOOLEAN NOT NULL DEFAULT TRUE,
  marketing_review_request_hours_after INTEGER NOT NULL DEFAULT 2,
  marketing_loyalty_auto_stamp BOOLEAN NOT NULL DEFAULT TRUE,
  marketing_referral_bonus_bif INTEGER NOT NULL DEFAULT 2000,
  -- Staff
  staff_show_earnings BOOLEAN NOT NULL DEFAULT FALSE,
  staff_commission_auto_calculate BOOLEAN NOT NULL DEFAULT TRUE,
  staff_require_checkin BOOLEAN NOT NULL DEFAULT FALSE,
  -- Loyalty
  loyalty_stamps_per_card INTEGER NOT NULL DEFAULT 10,
  loyalty_reward_description TEXT NOT NULL DEFAULT 'Service gratuit',
  loyalty_expiry_days INTEGER NOT NULL DEFAULT 365,
  -- Reviews
  reviews_auto_publish BOOLEAN NOT NULL DEFAULT TRUE,
  reviews_moderation_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  reviews_min_rating_alert INTEGER NOT NULL DEFAULT 2,
  -- Payments
  payment_grace_period_minutes INTEGER NOT NULL DEFAULT 30,
  payment_auto_invoice BOOLEAN NOT NULL DEFAULT TRUE,
  -- Hours
  timezone TEXT NOT NULL DEFAULT 'Africa/Bujumbura',
  -- Advanced
  advanced_double_booking BOOLEAN NOT NULL DEFAULT FALSE,
  advanced_overbooking_limit INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.salon_settings ENABLE ROW LEVEL SECURITY;
-- Matches services/invoices: owner+manager manage, no client/staff
-- visibility — booking/marketing/payment policy is an internal control,
-- not something to expose further down the role chain by default.
CREATE POLICY "salon_settings_owner_manager" ON public.salon_settings
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE OR REPLACE FUNCTION public.create_default_salon_settings()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO public.salon_settings (salon_id) VALUES (NEW.id) ON CONFLICT (salon_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS auto_salon_settings ON public.salons;
CREATE TRIGGER auto_salon_settings AFTER INSERT ON public.salons
  FOR EACH ROW EXECUTE FUNCTION public.create_default_salon_settings();

-- Backfill every salon created before this migration — the trigger above
-- only covers salons inserted from here on.
INSERT INTO public.salon_settings (salon_id)
SELECT id FROM public.salons
ON CONFLICT (salon_id) DO NOTHING;