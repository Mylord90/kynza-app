-- ================================================================
-- KYNZA — Migration 007 — Phase 2 / Subphase B — Services catalogue
-- ================================================================

CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  duration_min INT NOT NULL CHECK(duration_min > 0),
  buffer_min INT NOT NULL DEFAULT 0 CHECK(buffer_min >= 0),
  price_bif INT NOT NULL CHECK(price_bif >= 0),
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_services_salon
  ON public.services(salon_id, display_order)
  WHERE deleted_at IS NULL;

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "services_owner_manager_manage" ON public.services
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "services_public_select" ON public.services
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);

CREATE TRIGGER services_updated_at BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
