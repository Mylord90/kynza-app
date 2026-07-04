# GATE 0 — P0 Remediation Verification (blocking, run first, alone)

> KYNZA Final Enterprise Verification & Go/No-Go Audit — Gate 0. Verifies the disposition of the
> P0 found in the prior certification pass (`docs/certification/PHASE_6_SECURITY_OFFENSIVE.md`):
> unauthenticated read access to `staff_profiles.invitation_token`, exploitable to claim a staff
> role in any salon.

## 1. Exploitation-evidence check (production, `hhdkjfpgaklhrhfoxlhj`)

Read-only, with the user's explicit sign-off to query production directly via
`supabase db query --linked`. Findings:

| Check | Result |
|---|---|
| `activity_logs` rows for `type_action ilike '%invitation%'` | Exactly 2, both `staff_invitation_accepted`, both `2026-06-24` (dev/testing window), same `salon_id` (`34b44dd2-…`) |
| `ip_address`/`device_info`/`platform` on those 2 rows | `NULL` — `accept-invitation` does not currently log caller IP/device, so activity_logs cannot positively rule out a hostile accept even for these 2; it can only confirm no *additional* accepts happened |
| Users linked to more than one `staff_profiles` row (cross-tenant claim signal) | **0 rows** — no auth account has ever claimed staff status at more than one salon |
| `staff_profiles` pending/unclaimed (`invitation_accepted_at IS NULL`) right now | **0** — production currently has exactly 2 `staff_profiles` rows total, both already accepted |
| `pg_stat_user_tables` for `staff_profiles` | `seq_scan=115`, `seq_tup_read=195`, `idx_scan=20`, `n_live_tup=2` since project creation (2026-05-19) — consistent with ordinary dev/QA traffic; **not** a meaningful signal either way given the table has only ever held 2 rows (an attacker "enumerating" this table gets the same 2 rows every time, so scan volume can't distinguish scraping from normal app use) |

**Honest limitation — not glossed over**: this environment has no Management API personal-access
token or dashboard session, so the actual API-gateway/Auth logs (Logflare-backed — source IPs,
unauthenticated request rate, User-Agent patterns for direct `PostgREST` calls) were **not
accessible** and were **not** checked. Everything above is a Postgres-level proxy, not a real
access-log audit. This should be escalated to Mylord as a follow-up: someone with dashboard/Management-API
access should pull the Logs Explorer for `staff_profiles` REST reads over the token's entire
lifetime (project creation to today) filtered to `anon`-role/no-`Authorization` requests.

**Conclusion**: no evidence of actual exploitation found in what was checkable. Confidence in
"clean" is moderate-to-low, not high — driven mostly by production having almost no real data on
it yet (2 rows), not by a clean access-log audit. Do not read this as "confirmed not exploited."

## 2. Has a fix been applied?

**No.** Confirmed via `supabase migration list --linked`: migration
`20260704190000_cp6_fix_staff_invitation_token_exposure.sql` exists locally (74 total local
migration files) but has no `Applied` timestamp against the linked remote — it is still draft-only,
exactly as CP6 left it. It has **not** been applied in this Gate either, per Rule 8 (no migration
reaches live Supabase without Mylord's explicit per-file approval).

## 3. Token invalidation for already-issued invitations

Added to the migration (was missing from CP6's draft): an idempotent
`UPDATE ... SET invitation_token = gen_random_uuid() WHERE invitation_accepted_at IS NULL AND
deleted_at IS NULL`. Scoped to unclaimed invitations only — already-accepted rows are left alone
because `accept-invitation` already refuses any token where `invitation_accepted_at IS NOT NULL`,
so a leaked-but-already-consumed token has no further replay value.

- **Production impact of this statement, as of 2026-07-04**: zero rows (no pending invitations
  exist right now) — a no-op today, but must ship anyway since that could change before Mylord
  approves and applies this migration, and it's needed on `kynza-dr-scratch` (carries pending
  synthetic invitations from CP5/CP6).
- **Operational note for Mylord**: regenerating the token invalidates any invite link already sent
  to a prospective staff member (e.g. via WhatsApp/SMS through `share_service.dart`). Owners with a
  pending invitation outstanding at the time this migration is applied will need to re-share the
  invite link from the staff detail screen after the token changes. Not a code change — just an
  operational heads-up for whoever applies this.

## 4. The fix itself — completed this Gate, not just drafted

CP6 stopped short of applying its own draft because it could not "conclusively trace" which
Flutter screen depends on the public policy. That trace is now complete:

**Repo-wide search** for every consumer of `salonStaffProvider`
(`lib/features/staff/application/providers/staff_providers.dart:27`, `.select()` on the
`staff_profiles` base table, all columns) found 12 call sites. Classified by reachability:

| Screen | Role required | Depends on the public policy? |
|---|---|---|
| `staff_list_screen.dart`, `staff_invite_screen.dart`, `staff_picker_screen.dart` ("Horaires par staff"/"Pauses & absences"), `commission_screen.dart`, `advanced_dashboard_screen.dart`, `permission_group_detail_screen.dart`, `walkin_booking_sheet.dart` ("+ Nouveau RDV", owner/staff creates a booking **for** a walk-in client), `app_router.dart` `_OwnerStaffHoursLoader`, `_OwnerTeamDetailLoader` | owner / manager / staff (authenticated) | **No** — these already get their access from `owner_manage_staff`/`manager_view_staff`/`staff_own_profile_select`, independent of the public policy. Dropping the public policy does not affect them. |
| `practitioner_selection_screen.dart` (client's own "choose a practitioner" step, driven by `bookingFlowProvider`) | client (authenticated) or, before RLS closes it, unauthenticated | **Yes — the one real precondition.** |

**Fix applied to the repo (not yet deployed/built)**:
- `lib/features/staff/application/providers/staff_providers.dart` — added
  `publicSalonStaffProvider`, a `FutureProvider.family` reading the new
  `v_staff_directory_public` view (id, salon_id, role, display_name, avatar_url, bio, specialties,
  is_active, invitation_accepted_at — no `invitation_token`/`phone`/`invited_by`).
  `invitation_accepted_at` is included deliberately: `practitioner_selection_screen.dart` filters
  out not-yet-accepted staff via `StaffProfileModelX.isPending`, and a bare timestamp carries none
  of `invitation_token`'s bearer-credential risk.
- `lib/features/booking/presentation/screens/practitioner_selection_screen.dart` — re-pointed from
  `salonStaffProvider` to `publicSalonStaffProvider`. Verified `PractitionerCard` (its only
  renderer) uses only `displayName`/`avatarUrl`/`specialties` — all present in the view, no
  breakage.
- `flutter analyze` on both changed files: 0 issues.
- Migration `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql`
  updated with the resolved precondition note, the widened view (added
  `invitation_accepted_at`), and the token-invalidation statement from §3.

**Still not applied to any live project** (local Supabase stack is unavailable in this environment —
`supabase status` fails, no Docker; `kynza-dr-scratch` and production both require Mylord's
explicit approval per Rule 8). The Flutter-side change is a normal, reversible, git-tracked code
change and does not by itself reach any user until built/released — it was completed here because
it was the actual blocker CP6 identified, not because it bypasses the migration-approval rule.

## Exit criteria

- [x] Checked for exploitation evidence — reported honestly, including what could **not** be
      checked (Logflare/API-gateway logs — no Management API access in this environment).
- [x] Confirmed the fix has not been applied.
- [x] Every already-issued invitation token is covered by an invalidation step in the draft
      migration (scoped to unclaimed ones — accepted ones don't need it).
- [x] The fix is fully drafted, including the previously-missing Flutter precondition — CP6's
      "needs more time" blocker is now resolved, not just re-described.
- [ ] **Migration NOT applied** — requires Mylord's explicit review and approval, separate from any
      other draft migration in this pass (per the prompt's own instruction). This is the one
      action item this Gate cannot close on its own authority.

## Escalation to Mylord

This is still an open P0 until the migration is reviewed and applied. Recommended action:
1. Review `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql` (now
   updated) and this document.
2. Approve applying it to `kynza-dr-scratch` first, confirm `practitioner_selection_screen.dart`
   still works end-to-end there (booking flow, practitioner picker) against the now-restricted
   view, then approve production.
3. Separately, get someone with Supabase dashboard/Management-API access to pull real API-gateway
   logs for `staff_profiles` reads over the token's full lifetime — this Gate could not do that
   itself and that gap should not be silently dropped.
4. After applying, any owner with a pending invitation outstanding needs to re-share the invite
   link (token will have changed under them).
