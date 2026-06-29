-- ================================================================
-- PHASE 5 — Team Management: per-staff commission rate + ledger.
-- ================================================================

ALTER TABLE public.staff_profiles
  ADD COLUMN IF NOT EXISTS commission_type TEXT NOT NULL DEFAULT 'percent'
    CHECK(commission_type IN('percent','fixed')),
  ADD COLUMN IF NOT EXISTS commission_rate NUMERIC NOT NULL DEFAULT 0
    CHECK(commission_rate >= 0);

CREATE TABLE IF NOT EXISTS public.staff_commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES public.staff_profiles(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  booking_id UUID NOT NULL UNIQUE REFERENCES public.bookings(id),
  rate_type TEXT NOT NULL CHECK(rate_type IN('percent','fixed')),
  rate_value NUMERIC NOT NULL,
  amount_bif INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN('pending','paid')),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_staff
  ON public.staff_commissions(staff_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_staff_commissions_salon
  ON public.staff_commissions(salon_id) WHERE deleted_at IS NULL;

ALTER TABLE public.staff_commissions ENABLE ROW LEVEL SECURITY;

-- Owner manages all commissions in their salon (mark paid, etc).
CREATE POLICY "owner_manage_commissions" ON public.staff_commissions
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id))
  WITH CHECK (public.has_role(auth.uid(), 'owner', salon_id));

-- R11 — a staff member only ever sees their own commission rows, never
-- a colleague's.
CREATE POLICY "staff_own_commissions_select" ON public.staff_commissions
  FOR SELECT USING (
    staff_id IN (
      SELECT id FROM public.staff_profiles WHERE user_id = auth.uid()
    )
  );

CREATE TRIGGER staff_commissions_updated_at BEFORE UPDATE ON public.staff_commissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();