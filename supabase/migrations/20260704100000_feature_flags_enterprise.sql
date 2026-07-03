-- Phase 3 (Backend Enterprise Completion) — Feature Flags Enterprise
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8 of
-- docs/prompts/KYNZA_CLAUDE_CODE_PROMPT_BACKEND_ENTERPRISE_COMPLETION.md.
--
-- Extends the existing feature_flags / salon_feature_overrides system
-- (20260630110000_phase4_feature_flags.sql) rather than replacing it:
--   1. Adds a `category` column for grouping (Booking/Loyalty/Referral/...).
--   2. Adds per-role overrides (role_feature_overrides), salon-scoped —
--      a truly global (cross-salon) per-role override is deliberately
--      deferred until a SYSTEM_ADMIN scope exists (Phase 1 audit finding,
--      assigned to Phase 2/CP3 of this pass).
--   3. Adds per-user overrides (user_feature_overrides), salon-scoped,
--      mirroring the existing user_permission_groups/user_permission_overrides
--      ownership model (owner manages overrides for users in their own
--      salon) rather than inventing a new access pattern.
--   4. Extends evaluate_feature_flag()'s resolution order to check the
--      new scopes before falling back to the existing salon/global logic.
--   5. Extends logs_self_insert_safe's type_action whitelist so the app
--      can audit override changes via the existing AuditLogger →
--      activity_logs pipeline (Phase 10 will build the query/report layer
--      on top of this; not duplicated here).

-- ─── 1. Category column ─────────────────────────────────────────────────────

ALTER TABLE public.feature_flags
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'general';

CREATE INDEX IF NOT EXISTS idx_feature_flags_category
  ON public.feature_flags(category);

-- Assign real categories to every flag from the brief's list (Booking,
-- Loyalty, Referral, Promotion, Analytics, Reviews, Subscriptions,
-- Commission, Notifications, ProxiPay, Google Maps, Leapa, Staff, Owner,
-- Client, Manager, Beta, Experimental). Works whether run before or after
-- the 20260703140000_feature_flags_registry.sql draft (UPDATE is a no-op
-- for rows that don't exist yet).
UPDATE public.feature_flags AS ff SET category = v.category
FROM (VALUES
  ('advanced_analytics',  'Analytics'),
  ('ai_scheduling',       'Analytics'),
  ('multi_location',      'Beta'),
  ('client_app_v2',       'Experimental'),
  ('instant_booking',     'Booking'),
  ('feature_google_maps', 'Google Maps'),
  ('feature_proxipay',    'ProxiPay'),
  ('feature_ble',         'ProxiPay'),
  ('feature_nfc',         'ProxiPay'),
  ('feature_qr',          'ProxiPay'),
  ('feature_notifications','Notifications'),
  ('feature_reviews',     'Reviews'),
  ('feature_marketing',   'Promotion'),
  ('feature_referrals',   'Referral'),
  ('feature_loyalty',     'Loyalty'),
  ('feature_commissions', 'Commission'),
  ('feature_dashboard',   'Analytics'),
  ('feature_pdf',         'Analytics'),
  ('feature_csv',         'Analytics'),
  ('feature_export',      'Analytics'),
  ('feature_crashlytics', 'Experimental'),
  ('feature_i18n',        'Experimental'),
  ('feature_chat',        'Beta'),
  ('feature_ai',          'Beta'),
  ('feature_offline',     'Experimental'),
  ('feature_sync',        'Experimental'),
  ('feature_subscriptions','Subscriptions'),
  ('feature_staff',       'Staff'),
  ('feature_owner',       'Owner'),
  ('feature_manager',     'Manager'),
  ('feature_support',     'Client'),
  ('leapa_enabled',       'Leapa'),
  ('feature_app_check',   'Experimental')
) AS v(key, category)
WHERE ff.key = v.key;

-- ─── 2. Per-role overrides (salon-scoped) ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.role_feature_overrides (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id   UUID        NOT NULL REFERENCES public.salons(id)         ON DELETE CASCADE,
  role       TEXT        NOT NULL,
  flag_key   TEXT        NOT NULL REFERENCES public.feature_flags(key) ON DELETE CASCADE,
  is_enabled BOOLEAN     NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (salon_id, role, flag_key)
);
ALTER TABLE public.role_feature_overrides ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_role_feature_overrides_salon
  ON public.role_feature_overrides (salon_id, role);

CREATE TRIGGER trg_role_feature_overrides_updated_at
  BEFORE UPDATE ON public.role_feature_overrides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE POLICY "role_feature_overrides_owner_all"
  ON public.role_feature_overrides FOR ALL TO authenticated
  USING     (has_role(auth.uid(), 'owner', salon_id))
  WITH CHECK (has_role(auth.uid(), 'owner', salon_id));

CREATE POLICY "role_feature_overrides_manager_select"
  ON public.role_feature_overrides FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'manager', salon_id));

-- ─── 3. Per-user overrides (salon-scoped, mirrors user_permission_groups) ───

CREATE TABLE IF NOT EXISTS public.user_feature_overrides (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id   UUID        NOT NULL REFERENCES public.salons(id)         ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES public.users(id)          ON DELETE CASCADE,
  flag_key   TEXT        NOT NULL REFERENCES public.feature_flags(key) ON DELETE CASCADE,
  is_enabled BOOLEAN     NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (salon_id, user_id, flag_key)
);
ALTER TABLE public.user_feature_overrides ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_user_feature_overrides_salon_user
  ON public.user_feature_overrides (salon_id, user_id);

CREATE TRIGGER trg_user_feature_overrides_updated_at
  BEFORE UPDATE ON public.user_feature_overrides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Owner may only grant/revoke for a user who actually belongs to their salon
-- (prevents an owner from setting an override for another salon's user).
CREATE POLICY "user_feature_overrides_owner_all"
  ON public.user_feature_overrides FOR ALL TO authenticated
  USING (
    has_role(auth.uid(), 'owner', salon_id)
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = user_feature_overrides.user_id AND u.salon_id = user_feature_overrides.salon_id
    )
  )
  WITH CHECK (
    has_role(auth.uid(), 'owner', salon_id)
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = user_feature_overrides.user_id AND u.salon_id = user_feature_overrides.salon_id
    )
  );

CREATE POLICY "user_feature_overrides_manager_select"
  ON public.user_feature_overrides FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'manager', salon_id));

-- A user may also read their own overrides (needed so evaluate_feature_flag,
-- SECURITY INVOKER, can see their own row when it runs as them).
CREATE POLICY "user_feature_overrides_self_select"
  ON public.user_feature_overrides FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- ─── 4. evaluate_feature_flag() — extended resolution order ────────────────
--
-- Resolution order (highest priority first):
--   1. Per-user override (user_feature_overrides)
--   2. Per-role override, scoped to the caller's own salon (role_feature_overrides)
--   3. Per-salon override (salon_feature_overrides) — unchanged from Phase 4
--   4. Global flag + rollout percentage — unchanged from Phase 4

CREATE OR REPLACE FUNCTION public.evaluate_feature_flag(p_key TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
AS $$
DECLARE
  v_salon_id UUID;
  v_role     TEXT;
  v_override BOOLEAN;
  v_enabled  BOOLEAN;
  v_rollout  INT;
BEGIN
  SELECT u.salon_id, u.role INTO v_salon_id, v_role
  FROM public.users u WHERE u.id = auth.uid() LIMIT 1;

  -- 1. Per-user override
  SELECT ufo.is_enabled INTO v_override
  FROM public.user_feature_overrides ufo
  WHERE ufo.user_id = auth.uid() AND ufo.flag_key = p_key LIMIT 1;
  IF FOUND THEN RETURN v_override; END IF;

  -- 2. Per-role override (caller's own salon)
  IF v_salon_id IS NOT NULL AND v_role IS NOT NULL THEN
    SELECT rfo.is_enabled INTO v_override
    FROM public.role_feature_overrides rfo
    WHERE rfo.salon_id = v_salon_id AND rfo.role = v_role AND rfo.flag_key = p_key LIMIT 1;
    IF FOUND THEN RETURN v_override; END IF;
  END IF;

  -- 3. Per-salon override (unchanged)
  SELECT sfo.is_enabled INTO v_override
  FROM public.salon_feature_overrides sfo
  WHERE sfo.salon_id = v_salon_id AND sfo.flag_key = p_key LIMIT 1;
  IF FOUND THEN RETURN v_override; END IF;

  -- 4. Global flag + rollout (unchanged)
  SELECT ff.is_enabled, ff.rollout_percentage INTO v_enabled, v_rollout
  FROM public.feature_flags ff WHERE ff.key = p_key LIMIT 1;
  IF NOT FOUND   THEN RETURN false; END IF;
  IF NOT v_enabled THEN RETURN false; END IF;
  IF v_rollout >= 100 THEN RETURN true; END IF;
  IF v_salon_id IS NULL THEN RETURN false; END IF;

  RETURN (('x' || substr(md5(v_salon_id::TEXT || p_key), 1, 8))::bit(32)::INT
          & 2147483647) % 100 < v_rollout;
END;
$$;

-- ─── 5. Audit trail — extend the existing whitelist, don't duplicate it ────

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
      'feature_flag_override_set', 'feature_flag_override_removed'
    )
  );
