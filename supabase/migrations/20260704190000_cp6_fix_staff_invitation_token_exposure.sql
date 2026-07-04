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
-- ⚠ DEPLOYMENT PRECONDITION — RESOLVED in GATE 0 of the Final Enterprise Verification pass
-- (docs/certification-v2/GATE_0_P0_REMEDIATION.md). Repo-wide trace of every reader of
-- `salonStaffProvider` (lib/features/staff/application/providers/staff_providers.dart) found
-- exactly ONE consumer reachable by an unauthenticated/client-role caller:
-- lib/features/booking/presentation/screens/practitioner_selection_screen.dart (the client's own
-- "choose a practitioner" step in the booking flow, driven by `bookingFlowProvider`). Every other
-- consumer (staff_list_screen, staff_invite_screen, staff_picker_screen, commission_screen,
-- advanced_dashboard_screen, permission_group_detail_screen, walkin_booking_sheet, both
-- `_Owner*Loader` router widgets) is an owner/manager/staff-authenticated screen that already gets
-- its access from `owner_manage_staff`/`manager_view_staff`/`staff_own_profile_select` — none of
-- them depend on the public policy this migration drops. A companion Flutter change (see that same
-- doc) re-points `practitioner_selection_screen.dart` at a new `publicSalonStaffProvider`, which
-- queries `v_staff_directory_public` below instead of the base table. Land that Flutter change
-- (already committed to this branch) before this migration is applied — the two must ship together
-- or the practitioner-selection screen will 403/empty for client users between deploys.

-- invitation_accepted_at is included (unlike invitation_token/phone/invited_by): the client
-- booking flow needs it to exclude not-yet-accepted staff from the practitioner picker
-- (StaffProfileModelX.isPending), and a bare timestamp of "did this person accept yet" carries
-- none of invitation_token's bearer-credential risk.
--
-- UPDATE (Remediation v1, Phase 2) — real bug found by actually testing this migration on
-- kynza-dr-scratch rather than trusting the draft: `security_invoker = true` makes the view
-- apply the QUERYING role's RLS on the underlying `staff_profiles` table, not just the view's own
-- WHERE clause. Since this migration drops the only policy that ever let `anon`/unauthenticated
-- callers see staff_profiles rows at all, an invoker-security view returns ZERO rows for exactly
-- the audience it exists to serve — confirmed live: anon got `[]` from this view immediately after
-- applying, while an authenticated staff member only ever saw their own row (via
-- `staff_own_profile_select`), never a salon-mate's. That would have silently emptied the client
-- booking flow's practitioner picker in production — a full outage of a legitimate feature, not a
-- security improvement. Fixed by removing `security_invoker` (views default to definer-style,
-- running as the view owner) so the view intentionally grants controlled, narrow access beyond
-- what base-table RLS allows anon/authenticated — safe specifically because the view's own column
-- list already excludes every sensitive field (`invitation_token`/`phone`/`invited_by`) and its
-- WHERE clause already scopes to `is_active`/non-deleted rows only. This is the same
-- security-definer-view pattern flagged generically by the Postgres advisor elsewhere in this
-- codebase (see Master Issues Matrix P2-4) — here it is the deliberate, correct tool, not an
-- oversight, and is called out explicitly rather than left as an unexplained advisor exception.
CREATE OR REPLACE VIEW public.v_staff_directory_public
AS
SELECT id, salon_id, role, display_name, avatar_url, bio, specialties, is_active,
       invitation_accepted_at
FROM public.staff_profiles
WHERE deleted_at IS NULL AND is_active = true;

GRANT SELECT ON public.v_staff_directory_public TO anon, authenticated;

DROP POLICY IF EXISTS "staff_profiles_public_select" ON public.staff_profiles;

-- No replacement public policy on the base table — public/unauthenticated browse now goes
-- exclusively through the column-limited view above. `owner_manage_staff`, `manager_view_staff`,
-- and `staff_own_profile_select`/`staff_own_profile_update` are untouched and continue to grant
-- full-column access to the roles that legitimately need `invitation_token`/`phone`/`invited_by`.

-- TOKEN INVALIDATION — every invitation_token issued before this fix was, for as long as the
-- public policy existed, readable by anyone unauthenticated. Treat all of them as potentially
-- compromised (per Gate 0 instructions), not just the ones we have log evidence against. This is
-- idempotent and safe to run regardless of environment state: as of this draft, production
-- (hhdkjfpgaklhrhfoxlhj) has zero rows with invitation_accepted_at IS NULL (verified via
-- `supabase db query --linked`, 2026-07-04), so this is a no-op there today — but the statement
-- must still ship in case that changes before this migration is actually applied, and to cover
-- staging/kynza-dr-scratch, which does carry pending synthetic invitations from CP5/CP6.
-- Already-accepted rows are NOT touched: accept-invitation already rejects any token where
-- invitation_accepted_at IS NOT NULL, so a leaked-but-consumed token is not independently
-- replayable — regenerating it would only churn data with no security benefit.
UPDATE public.staff_profiles
SET invitation_token = gen_random_uuid()
WHERE invitation_accepted_at IS NULL
  AND deleted_at IS NULL;
