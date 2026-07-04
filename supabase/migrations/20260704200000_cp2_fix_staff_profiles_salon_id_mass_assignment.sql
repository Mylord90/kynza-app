-- DRAFT — reviewed but NOT applied to any project, per Rule 8. Remediation for a real, live
-- P1/P2 finding from the KYNZA Final Enterprise Verification pass, CP2 (Deep Security — mass
-- assignment): docs/certification-v2/CP2_DEEP_SECURITY.md.
--
-- FINDING: `staff_own_profile_update`'s WITH CHECK (supabase/migrations/20260623220000_
-- staff_management.sql) pins `role` to its previous value but never pins `salon_id`. Confirmed
-- live and exploitable against kynza-dr-scratch: a real authenticated staff member successfully
-- PATCHed their own `staff_profiles.salon_id` to a DIFFERENT salon's id via a direct REST call —
-- no Edge Function, no app code involved, just a raw `PATCH /rest/v1/staff_profiles`. Reverted
-- immediately after with a service-role call; the QA fixture is back to its original state.
--
-- WHY THIS MATTERS: `has_role()` (public.has_role) authorizes against `users.salon_id`, which
-- *is* protected (`protect_user_columns` trigger — role/salon_id immutable there), so this bug
-- does NOT let an attacker pass `has_role(auth.uid(), 'staff', <other_salon>)` checks and does NOT
-- grant read/write access to another salon's RLS-protected data (bookings, clients, revenue).
-- The real impact is narrower but still real: `staff_profiles.salon_id` is queried directly (not
-- via has_role) in booking-availability eligibility
-- (AvailabilityService._eligiblePractitionerIds, lib/core/services/availability_service.dart) and
-- in the client-facing practitioner directory (v_staff_directory_public, once the Gate 0 fix
-- lands). A malicious staff account at Salon A can inject themselves as an apparent staff member
-- of Salon B — showing up in Salon B's public practitioner list and potentially getting assigned
-- as `practitioner_id` on a Salon B booking they have no real relationship with, corrupting that
-- tenant's schedule/staff-directory integrity (an integrity/business-logic issue, not a
-- confidentiality breach).
--
-- FIX: same pattern already used for `role` — pin `salon_id` to its previous value in the
-- WITH CHECK clause too.
DROP POLICY IF EXISTS "staff_own_profile_update" ON public.staff_profiles;

CREATE POLICY "staff_own_profile_update" ON public.staff_profiles
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND role IS NOT DISTINCT FROM (
      SELECT role FROM public.staff_profiles WHERE user_id = auth.uid()
    )
    AND salon_id IS NOT DISTINCT FROM (
      SELECT salon_id FROM public.staff_profiles WHERE user_id = auth.uid()
    )
  );

-- No Flutter-side precondition here (unlike the Gate 0 fix): StaffRepositoryImpl.updateStaff()
-- (lib/features/staff/data/repositories/staff_repository_impl.dart) already only ever sends
-- display_name/bio/phone/specialties/avatar_url — it never sends salon_id, so no legitimate call
-- site is affected by tightening this WITH CHECK.
