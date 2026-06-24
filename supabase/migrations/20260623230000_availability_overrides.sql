-- ================================================================
-- KYNZA — Migration 009 — Phase 2 / Subphase D — Availability overrides
-- ================================================================

CREATE TABLE IF NOT EXISTS public.availability_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  staff_id UUID REFERENCES public.staff_profiles(id),
  date DATE NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT false,
  opens_at TIME,
  closes_at TIME,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_availability_date
  ON public.availability_overrides(salon_id, staff_id, date)
  WHERE deleted_at IS NULL;

ALTER TABLE public.availability_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_manage_availability" ON public.availability_overrides
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "availability_public_select" ON public.availability_overrides
  FOR SELECT USING (deleted_at IS NULL);

CREATE TRIGGER availability_updated_at BEFORE UPDATE ON public.availability_overrides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
