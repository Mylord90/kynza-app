-- ================================================================
-- KYNZA — Migration 021 — Phase 2.2 / Module 3 — Advanced availability
-- staff_working_hours (per-staff override of salon working_hours) +
-- staff_breaks (recurring weekly pauses) + availability_exceptions
-- (multi-day vacations/closures/public holidays). Complements, not
-- replaces, the existing single-day public.availability_overrides table.
-- ================================================================

-- 1. staff_working_hours — overrides public.working_hours per staff/day
CREATE TABLE IF NOT EXISTS public.staff_working_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES public.staff_profiles(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  day_of_week INT NOT NULL CHECK(day_of_week BETWEEN 0 AND 6),
  opens_at TIME,
  closes_at TIME,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(staff_id, day_of_week)
);

ALTER TABLE public.staff_working_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_manage_staff_hours" ON public.staff_working_hours
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "staff_own_hours_manage" ON public.staff_working_hours
  FOR ALL USING (
    staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "staff_hours_public_select" ON public.staff_working_hours
  FOR SELECT USING (deleted_at IS NULL);

CREATE TRIGGER staff_working_hours_updated_at BEFORE UPDATE ON public.staff_working_hours
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. staff_breaks — recurring weekly pauses (lunch, etc.)
CREATE TABLE IF NOT EXISTS public.staff_breaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES public.staff_profiles(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  day_of_week INT NOT NULL CHECK(day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  label TEXT NOT NULL DEFAULT 'Pause',
  is_recurring BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_staff_breaks_staff
  ON public.staff_breaks(staff_id, day_of_week)
  WHERE deleted_at IS NULL;

ALTER TABLE public.staff_breaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_manage_breaks" ON public.staff_breaks
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "staff_own_breaks_manage" ON public.staff_breaks
  FOR ALL USING (
    staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "staff_breaks_public_select" ON public.staff_breaks
  FOR SELECT USING (deleted_at IS NULL);

CREATE TRIGGER staff_breaks_updated_at BEFORE UPDATE ON public.staff_breaks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. availability_exceptions — multi-day closures/vacations/holidays,
-- salon-wide (staff_id NULL) or staff-specific.
CREATE TABLE IF NOT EXISTS public.availability_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  staff_id UUID REFERENCES public.staff_profiles(id),
  exception_type TEXT NOT NULL CHECK(exception_type IN(
    'holiday', 'vacation', 'special_closure', 'special_opening', 'public_holiday'
  )),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  label TEXT NOT NULL,
  opens_at TIME,
  closes_at TIME,
  is_closed BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  CHECK (end_date >= start_date)
);
CREATE INDEX IF NOT EXISTS idx_exceptions_salon_date
  ON public.availability_exceptions(salon_id, start_date, end_date)
  WHERE deleted_at IS NULL;

ALTER TABLE public.availability_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_manage_exceptions" ON public.availability_exceptions
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "staff_own_exceptions_manage" ON public.availability_exceptions
  FOR ALL USING (
    staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "exceptions_public_select" ON public.availability_exceptions
  FOR SELECT USING (deleted_at IS NULL);

CREATE TRIGGER exceptions_updated_at BEFORE UPDATE ON public.availability_exceptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. Burundi public holidays (seed for 2026 — the year this migration
-- ships in; recurring years are a follow-up, not auto-generated here).
-- Backfills every salon that exists at migration time; a salon created
-- afterwards does not automatically get these rows (no trigger wired —
-- documented as a known gap in PHASE2_2_SUMMARY.md).
INSERT INTO public.availability_exceptions
  (salon_id, exception_type, start_date, end_date, label, is_closed)
SELECT
  s.id,
  'public_holiday',
  holidays.date_val::DATE,
  holidays.date_val::DATE,
  holidays.label,
  true
FROM public.salons s
CROSS JOIN (VALUES
  ('2026-01-01', 'Jour de l''An'),
  ('2026-02-05', 'Journée de l''Unité'),
  ('2026-04-05', 'Dimanche de Pâques'),
  ('2026-05-01', 'Fête du Travail'),
  ('2026-05-14', 'Ascension'),
  ('2026-06-26', 'Fête de l''Indépendance'),
  ('2026-07-01', 'Fête de l''Indépendance (Suite)'),
  ('2026-08-15', 'Assomption'),
  ('2026-10-13', 'Journée de Rwagasore'),
  ('2026-10-21', 'Journée des Nations Unies'),
  ('2026-11-01', 'Toussaint'),
  ('2026-12-25', 'Noël')
) AS holidays(date_val, label)
WHERE s.deleted_at IS NULL
ON CONFLICT DO NOTHING;
