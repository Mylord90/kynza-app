-- ================================================================
-- KYNZA — Migration 013 — Notification anti-spam quota (R12 / R14)
-- Max 2 promo sends per salon per week — backs the Owner Dashboard's
-- "Fill My Day" marketing feature.
-- ================================================================

CREATE TABLE IF NOT EXISTS public.notification_quota (
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  channel TEXT NOT NULL CHECK(channel IN('whatsapp_promo','whatsapp_general')),
  window_start TIMESTAMPTZ NOT NULL,
  count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (salon_id, channel, window_start)
);

ALTER TABLE public.notification_quota ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_select_quota" ON public.notification_quota
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- No client INSERT/UPDATE policy — only check_and_increment_promo_quota()
-- (SECURITY DEFINER, called from the fill-my-day Edge Function) writes here.

CREATE OR REPLACE FUNCTION public.check_and_increment_promo_quota(p_salon_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_week_start TIMESTAMPTZ := date_trunc('week', NOW());
  v_count INT;
BEGIN
  INSERT INTO public.notification_quota (salon_id, channel, window_start, count)
  VALUES (p_salon_id, 'whatsapp_promo', v_week_start, 1)
  ON CONFLICT (salon_id, channel, window_start)
  DO UPDATE SET count = public.notification_quota.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= 2;
END; $$;

REVOKE EXECUTE ON FUNCTION public.check_and_increment_promo_quota(UUID) FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.check_and_increment_promo_quota(UUID) TO service_role;
