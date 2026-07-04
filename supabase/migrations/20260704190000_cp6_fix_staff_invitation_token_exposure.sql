-- DRAFT — reviewed but NOT applied to any project, per Rule 8. Proposed remediation for a
-- CRITICAL P0 finding from the KYNZA Enterprise Final Certification Pass, CP6 (Phase 5 —
-- Security Offensive): docs/certification/PHASE_6_SECURITY_OFFENSIVE.md.
--
-- FINDING: `staff_profiles_public_select` ("(deleted_at IS NULL) AND (is_active = true)", granted
-- to PUBLIC — i.e. including fully unauthenticated `anon` requests) exposes EVERY column on every
-- active staff_profiles row to anyone on the internet, with no login required. This includes
-- `invitation_token` — the exact bearer credential `accept-invitation` (supabase/functions/
-- accept-invitation/index.ts) uses as the SOLE proof of identity to bind any caller's auth account
-- to that staff_profiles row (granting them staff role + salon_id at that salon). Confirmed live
-- via a real, unauthenticated curl request against production-mirrored schema on kynza-dr-scratch
-- (see the certification report for the exact request/response). This is a real account-takeover/
-- impersonation vector: anyone can enumerate pending invitations across every salon and self-
-- accept them.
--
-- ROOT CAUSE: Postgres RLS is row-level only — it cannot hide individual columns. The public
-- policy's row-level intent (let a would-be client browse a salon's staff list before booking) is
-- legitimate; the column-level side effect (leaking invitation_token, and to a lesser extent
-- phone/invited_by) is not.
--
-- FIX: replace direct public/authenticated table access with a column-limited view. Owner/manager/
-- staff-self access is UNCHANGED (their existing role-scoped policies on the base table are
-- untouched, so they still see invitation_token where legitimately needed, e.g. to share an
-- invite link).
--
-- ⚠ DEPLOYMENT PRECONDITION, NOT YET VERIFIED: whichever Flutter call site currently relies on
-- `staff_profiles_public_select` for the public/booking-flow staff browse (this checkpoint did not
-- conclusively trace which screen that is within its time budget) MUST be re-pointed at
-- `v_staff_directory_public` before this migration is applied, or that screen will start returning
-- empty staff lists for not-yet-affiliated client users. Confirm via a repo-wide search for
-- `.from('staff_profiles')` call sites reachable from an unauthenticated/client-role context before
-- applying.

CREATE OR REPLACE VIEW public.v_staff_directory_public
WITH (security_invoker = true)
AS
SELECT id, salon_id, role, display_name, avatar_url, bio, specialties, is_active
FROM public.staff_profiles
WHERE deleted_at IS NULL AND is_active = true;

GRANT SELECT ON public.v_staff_directory_public TO anon, authenticated;

DROP POLICY IF EXISTS "staff_profiles_public_select" ON public.staff_profiles;

-- No replacement public policy on the base table — public/unauthenticated browse now goes
-- exclusively through the column-limited view above. `owner_manage_staff`, `manager_view_staff`,
-- and `staff_own_profile_select`/`staff_own_profile_update` are untouched and continue to grant
-- full-column access to the roles that legitimately need `invitation_token`/`phone`/`invited_by`.
