-- ================================================================
-- KYNZA — Migration 008 — Phase 2 / Subphase C — Staff management
-- ================================================================

CREATE TABLE IF NOT EXISTS public.staff_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  role TEXT NOT NULL CHECK(role IN('manager','staff')) DEFAULT 'staff',
  display_name TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  phone TEXT,
  specialties TEXT[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  invited_by UUID REFERENCES public.users(id),
  invitation_token UUID NOT NULL DEFAULT gen_random_uuid(),
  invitation_accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_staff_salon
  ON public.staff_profiles(salon_id)
  WHERE deleted_at IS NULL AND is_active = true;
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_invitation_token
  ON public.staff_profiles(invitation_token);

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;

-- Owner manages all staff in their salon (only the Owner can promote
-- to manager — enforced again in the repository, not just RLS).
CREATE POLICY "owner_manage_staff" ON public.staff_profiles
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id));

-- Manager can view the team but never manage it.
CREATE POLICY "manager_view_staff" ON public.staff_profiles
  FOR SELECT USING (
    public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  );

-- A staff member can see and update their own profile row.
CREATE POLICY "staff_own_profile_select" ON public.staff_profiles
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "staff_own_profile_update" ON public.staff_profiles
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND role IS NOT DISTINCT FROM (
      SELECT role FROM public.staff_profiles WHERE user_id = auth.uid()
    )
  );

CREATE TRIGGER staff_profiles_updated_at BEFORE UPDATE ON public.staff_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Prevent deleting (soft) a staff member who still has future bookings —
-- the Owner must reassign those bookings to a substitute first.
-- (bookings table does not exist yet — Subphase E — so this trigger is
-- created there instead, against staff_profiles, once both tables exist.)

-- staff_services: which staff can perform which services
CREATE TABLE IF NOT EXISTS public.staff_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES public.staff_profiles(id),
  service_id UUID NOT NULL REFERENCES public.services(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(staff_id, service_id)
);
ALTER TABLE public.staff_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manager_manage_staff_services" ON public.staff_services
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "staff_services_public_select" ON public.staff_services
  FOR SELECT USING (deleted_at IS NULL);
