-- ================================================================
-- KYNZA — Migration 014 — Fill My Day uses native Share.share(), not a
-- WhatsApp Business API Edge Function (per the Owner Dashboard spec) —
-- so the quota counter itself carries no secret and is safe to expose
-- directly to authenticated owner/manager callers, as long as the
-- function verifies the caller's role itself (defense in depth, not
-- just GRANT/REVOKE).
-- ================================================================

CREATE OR REPLACE FUNCTION public.check_and_increment_promo_quota(p_salon_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_week_start TIMESTAMPTZ := date_trunc('week', NOW());
  v_count INT;
BEGIN
  IF NOT (
    public.has_role(auth.uid(), 'owner', p_salon_id)
    OR public.has_role(auth.uid(), 'manager', p_salon_id)
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  INSERT INTO public.notification_quota (salon_id, channel, window_start, count)
  VALUES (p_salon_id, 'whatsapp_promo', v_week_start, 1)
  ON CONFLICT (salon_id, channel, window_start)
  DO UPDATE SET count = public.notification_quota.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= 2;
END; $$;

GRANT EXECUTE ON FUNCTION public.check_and_increment_promo_quota(UUID) TO authenticated;
