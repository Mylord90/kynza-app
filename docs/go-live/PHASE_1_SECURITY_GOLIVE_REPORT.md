# Phase 1 — Security Go-Live Report

**Date**: 2026-07-06. **Scope**: deploy the fix for the last open P0 to production — nothing
else. Executed under the KYNZA — Production Go-Live Execution prompt's Phase 1, itself gated by
Rule 8 (nothing to production without Mylord's explicit, phase-by-phase authorization).

## What was deployed

**P0-1**, per `docs/KYNZA_FINAL_ENGINEERING_CERTIFICATION.md` Question 5: the
`staff_profiles_public_select` RLS policy (`(deleted_at IS NULL) AND (is_active = true)`, granted
to `{public}` — i.e. including fully unauthenticated `anon` requests) exposed every column on
every active `staff_profiles` row with no login required, including `invitation_token` — the sole
bearer credential `accept-invitation` uses to bind a caller's account to that staff row (granting
staff role + `salon_id`). A real account-takeover/impersonation vector.

Drafted, reviewed, and live-tested migration:
`supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql`. Companion
Flutter change (already committed, `ed13955` and earlier): `publicSalonStaffProvider`
(`lib/features/staff/application/providers/staff_providers.dart:52-58`), consumed by
`lib/features/booking/presentation/screens/practitioner_selection_screen.dart` — the one and
only unauthenticated-reachable consumer of the staff directory, repointed at the new
column-limited view instead of the base table.

## Before deploying — re-verification performed this session

- **Companion Flutter change confirmed committed and current**: `git status --short` clean;
  `git log` shows `staff_providers.dart` / `practitioner_selection_screen.dart` last touched by
  `ed13955` ("Phase 2 — live-test all 5 P0/P1/P2 security fixes on dr-scratch"), already on
  `main`, nothing pending.
- **Production schema re-checked live, not assumed**: `pg_policies` on `hhdkjfpgaklhrhfoxlhj`
  confirmed `staff_profiles_public_select` still present (`roles={public}`, `cmd=SELECT`,
  `qual=(deleted_at IS NULL) AND (is_active = true)`) — the vulnerability was still live at the
  moment this phase began, not already fixed by an earlier pass.
- **Blast radius re-checked live**: `select count(*) from staff_profiles where
  invitation_accepted_at is null and deleted_at is null` → **0**, both immediately before and
  immediately after deployment. No pending invitation existed at any point during this phase.
- **Migration re-verified against current production schema**: confirmed no other unapplied
  migration between the current state and `20260704190000` touches `staff_profiles` in a way this
  fix depends on (`20260704150000_business_observability_schema.sql` and
  `20260704180000_cp2_fk_indexes.sql` both touch the table but add unrelated columns/indexes, not
  preconditions for this view). This migration was applied standalone, not as part of the ordered
  batch — Phase 2's job, deliberately not pulled into this phase.
- **Dry run + live regression on `kynza-dr-scratch` (re-run this session, not carried forward
  from a prior pass' claim)**: confirmed dr-scratch already carries this exact fix live
  (`v_staff_directory_public` exists, `staff_profiles_public_select` absent from `pg_policies`
  there). Re-ran the full live security-fix suite
  (`flutter test test/live/remediation_v1_security_fixes_test.dart --tags live --run-skipped`)
  against it fresh:

  ```
  00:07 +0: staff_profiles.invitation_token is never returned to an unauthenticated caller
  00:07 +1: v_staff_directory_public serves the public staff directory without invitation_token/phone
  00:08 +2: a staff member cannot reassign their own staff_profiles.salon_id to another salon
  00:09 +3: create_default_document_templates rejects an unauthenticated caller
  00:09 +4: run-scheduled-actions rejects a caller with only the public anon key
  00:10 +5: schedule-reminders rejects a caller with only the public anon key
  00:10 +6: (tearDownAll)
  00:10 +6: All tests passed!
  ```

  Test #2 above is exactly the practitioner-selection-screen data path (it asserts
  `v_staff_directory_public` still serves real rows to `anon` with none of the sensitive columns)
  — this is the "legitimate flow must not break" check the gating protocol requires, executed
  against dr-scratch immediately before touching production.
- **Rollback procedure written and ready before deployment** (see below).

## Rollback procedure (written before deployment, not after)

If this fix needs to be reverted, the single statement below restores the prior (vulnerable)
behavior exactly:

```sql
CREATE POLICY "staff_profiles_public_select" ON public.staff_profiles
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);
```

This is a deliberate last resort only — reverting re-opens the exact P0 this phase closes. The
view (`v_staff_directory_public`) and its grants are additive and harmless to leave in place even
if this policy is restored, so the rollback does not touch them.

## Deployment — production (`hhdkjfpgaklhrhfoxlhj`)

Applied as 4 individual statements (the exact content of
`20260704190000_cp6_fix_staff_invitation_token_exposure.sql`, executed standalone via
`supabase db query --linked` rather than as part of the full pending-migration batch, since Phase
1's scope is this one fix only):

1. `CREATE OR REPLACE VIEW public.v_staff_directory_public AS SELECT id, salon_id, role,
   display_name, avatar_url, bio, specialties, is_active, invitation_accepted_at FROM
   public.staff_profiles WHERE deleted_at IS NULL AND is_active = true;` — applied, verified live
   (`select count(*) from public.v_staff_directory_public` → 2, matching the 2 real active staff
   rows in production).
2. `GRANT SELECT ON public.v_staff_directory_public TO anon, authenticated;` — applied.
3. `DROP POLICY IF EXISTS "staff_profiles_public_select" ON public.staff_profiles;` — applied.
4. `UPDATE public.staff_profiles SET invitation_token = gen_random_uuid() WHERE
   invitation_accepted_at IS NULL AND deleted_at IS NULL;` — applied; 0 rows affected (confirmed
   no pending invitation existed at deploy time — a no-op today, shipped per the migration's own
   design in case that ever changes).
5. `supabase migration repair --status applied 20260704190000 --linked` — migration history
   updated to reflect this fix is now live, so Phase 2's ordered batch will not attempt to
   reapply it.

## Proof after — real production verification, not inferred

**RLS state, re-queried directly**:
```
pg_policies on staff_profiles (hhdkjfpgaklhrhfoxlhj), post-deploy:
  manager_view_staff        SELECT {public}
  owner_manage_staff        ALL    {public}
  staff_own_profile_select  SELECT {public}
  staff_own_profile_update  UPDATE {public}
  (staff_profiles_public_select is gone)
```

**Live, unauthenticated, production-safe verification** (real HTTP requests against
`https://hhdkjfpgaklhrhfoxlhj.supabase.co`, anon key only, no auth token — the exact exploit
shape this P0 was ranked on):

| Request | Result |
|---|---|
| `GET /rest/v1/staff_profiles?select=id,invitation_token&invitation_accepted_at=is.null` (the exploit) | `200`, body `[]` — anon now sees **zero rows** on the base table; the vector is closed |
| `GET /rest/v1/v_staff_directory_public?select=*&limit=2` (the legitimate flow) | `200`, 2 real staff rows returned, **no** `invitation_token`/`phone`/`invited_by` field present — the practitioner-selection screen's data path still works |
| `GET /rest/v1/v_staff_directory_public?select=id,invitation_token` (column-level check) | `400`, `column v_staff_directory_public.invitation_token does not exist` — the sensitive column isn't reachable even by explicit name |

**Migration bookkeeping re-confirmed**: unapplied migration count dropped from 27 to **26**
(`supabase migration list --linked`), `20260704190000` now shows `remote: 20260704190000`
(applied). No other migration was touched.

**No code changed this phase** (production-only DB change) — `flutter analyze`/`flutter test`
were not expected to move and were not re-run as part of this phase's own validation; they remain
at the state confirmed in `KYNZA_FINAL_ENGINEERING_CERTIFICATION.md` (0 issues / 411 passed).

## Result

P0-1 is closed **live in production**, confirmed by direct query and a real unauthenticated
exploit attempt against the production API itself — not just on `kynza-dr-scratch`. Rollback
procedure is on file and untouched (not needed). 0 pending invitations existed at any point
during this deployment, so no token was ever actually at risk during the transition — but the
class of exposure (any future pending invitation) is now closed.

## Next

Per the governing prompt: **STOP here.** Phase 2 (migration deployment, 26 remaining) requires
Mylord's explicit authorization before starting.
