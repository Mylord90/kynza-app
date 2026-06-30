-- Phase 4 — Evolution Platform
-- Sub-system 1: Feature Flags V2 (per-salon overrides + gradual rollout)

-- ─── Global flag catalog ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.feature_flags (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  key                TEXT        NOT NULL UNIQUE,
  name               TEXT        NOT NULL,
  description        TEXT,
  is_enabled         BOOLEAN     NOT NULL DEFAULT false,
  rollout_percentage INT         NOT NULL DEFAULT 100
                                 CHECK (rollout_percentage BETWEEN 0 AND 100),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER trg_feature_flags_updated_at
  BEFORE UPDATE ON public.feature_flags
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Authenticated users read the catalog (admins write via service_role)
CREATE POLICY "feature_flags_authenticated_select"
  ON public.feature_flags FOR SELECT TO authenticated USING (true);

-- ─── Per-salon overrides ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.salon_feature_overrides (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id   UUID        NOT NULL REFERENCES public.salons(id)         ON DELETE CASCADE,
  flag_key   TEXT        NOT NULL REFERENCES public.feature_flags(key) ON DELETE CASCADE,
  is_enabled BOOLEAN     NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (salon_id, flag_key)
);
ALTER TABLE public.salon_feature_overrides ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_salon_feature_overrides_salon
  ON public.salon_feature_overrides (salon_id);

CREATE TRIGGER trg_salon_feature_overrides_updated_at
  BEFORE UPDATE ON public.salon_feature_overrides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Owner: full control over their salon's overrides
CREATE POLICY "salon_feature_overrides_owner_all"
  ON public.salon_feature_overrides FOR ALL TO authenticated
  USING     (has_role(auth.uid(), 'owner',   salon_id))
  WITH CHECK (has_role(auth.uid(), 'owner',   salon_id));

-- Manager: read-only (sees which features are active)
CREATE POLICY "salon_feature_overrides_manager_select"
  ON public.salon_feature_overrides FOR SELECT TO authenticated
  USING (has_role(auth.uid(), 'manager', salon_id));

-- ─── RPC: evaluate_feature_flag(key) ───────────────────────────────────────
--
-- Resolution order:
--   1. Salon-level override → return override.is_enabled
--   2. Global flag disabled → return false
--   3. rollout_percentage = 100 → return true
--   4. Deterministic bucket: hash(salon_id || key) mod 100 < rollout_percentage

CREATE OR REPLACE FUNCTION public.evaluate_feature_flag(p_key TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
AS $$
DECLARE
  v_salon_id UUID;
  v_override BOOLEAN;
  v_enabled  BOOLEAN;
  v_rollout  INT;
BEGIN
  SELECT u.salon_id INTO v_salon_id
  FROM public.users u WHERE u.id = auth.uid() LIMIT 1;

  SELECT sfo.is_enabled INTO v_override
  FROM public.salon_feature_overrides sfo
  WHERE sfo.salon_id = v_salon_id AND sfo.flag_key = p_key LIMIT 1;
  IF FOUND THEN RETURN v_override; END IF;

  SELECT ff.is_enabled, ff.rollout_percentage INTO v_enabled, v_rollout
  FROM public.feature_flags ff WHERE ff.key = p_key LIMIT 1;
  IF NOT FOUND   THEN RETURN false; END IF;
  IF NOT v_enabled THEN RETURN false; END IF;
  IF v_rollout >= 100 THEN RETURN true; END IF;
  IF v_salon_id IS NULL THEN RETURN false; END IF;

  -- Deterministic per-salon bucket (mask MSB to guarantee positive result)
  RETURN (('x' || substr(md5(v_salon_id::TEXT || p_key), 1, 8))::bit(32)::INT
          & 2147483647) % 100 < v_rollout;
END;
$$;

GRANT EXECUTE ON FUNCTION public.evaluate_feature_flag(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.evaluate_feature_flag(TEXT) FROM anon;

-- ─── Seed default flag catalog ──────────────────────────────────────────────

INSERT INTO public.feature_flags
  (key, name, description, is_enabled, rollout_percentage)
VALUES
  ('advanced_analytics', 'Analytiques avancées',
   'Graphiques de tendances et analyses prédictives',      false, 100),
  ('ai_scheduling',      'Planification IA',
   'Suggestions automatiques de créneaux par IA',          false, 100),
  ('multi_location',     'Multi-établissements',
   'Gestion de plusieurs salons depuis un compte',         false,   0),
  ('client_app_v2',      'App Client V2',
   'Nouvelle interface client (test A/B graduel)',         false,   0),
  ('instant_booking',    'Réservation instantanée',
   'Confirmation sans validation manuelle du gérant',       true, 100)
ON CONFLICT (key) DO NOTHING;