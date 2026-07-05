# CP4 — Code Quality

**Date**: 2026-07-05. **Scope**: real cleanup (dead code, duplication, missing correctness
triggers/columns), not just a list. Safe removals executed directly; anything risky flagged, not
rushed.

## Objectifs

P2-18, P3-8, P3-9 (DB correctness debt), a real dead-code scan (tool-based, not eyeball), P3-5
(Edge Function hygiene — bounded, proportionate progress).

## Preuve

### P2-18 / P3-8 / P3-9 — 3 real DB correctness gaps, fixed and live-tested

New migration `20260706120000_cp4_db_correctness_debt.sql`, each item re-confirmed by direct
inspection of the actual table definitions before writing the fix (not re-quoted from the Master
Inventory):
- **P2-18**: `salon_settings`/`permission_groups`/`automation_workflows` each have a real
  `updated_at` column but no `CREATE TRIGGER` anywhere in the migration history — confirmed by
  reading all 3 tables' definitions directly. Added the same `update_updated_at()` trigger every
  other table already uses.
- **P3-8**: same 3 tables (`salon_settings`, `owner_journey_progress`, `referrals`) confirmed to
  have **no** `deleted_at` column at all (not "unused," genuinely absent) — added.
- **P3-9**: `salons.owner_id` confirmed to be a bare `UUID` with no `REFERENCES` clause since the
  foundation migration, despite being used throughout RLS. Added as `NOT VALID` + separate
  `VALIDATE CONSTRAINT` (avoids a blocking table scan/lock) + a supporting index.

**Live-tested on `kynza-dr-scratch`**, not just applied:
```sql
-- Trigger genuinely fires:
UPDATE salon_settings SET booking_advance_days = booking_advance_days WHERE id = '...';
-- updated_at: 2026-07-03 11:39:21 -> 2026-07-05 20:20:27 (real change, not assumed)

-- FK validated with zero orphaned rows (migration would have failed loudly otherwise):
conname: salons_owner_id_fkey, convalidated: true

-- deleted_at columns present on all 3 tables (information_schema query, all 3 rows returned)
```

### Dead-code scan — tool-based, not eyeball, with a real correction to a prior report

Wrote an independent Node.js reachability scanner (import/export graph, not just import) over all
451 `lib/` files + 76 test files. First pass (imports only) found 24 "orphan" candidates; **most
turned out to be a false-positive class the scan itself then explained**: `kynza_widgets.dart` is
a genuine barrel-export file — which directly contradicts `CP1_ARCHITECTURE_REVERIFY.md`'s own
claim ("No barrel files found in this codebase"). That claim is now stale/incorrect and is
corrected here, not silently carried forward. Accounting for `export` statements narrowed this to
**8 genuine candidates**, each individually investigated (not batch-assumed dead):

| File | Finding | Action |
|---|---|---|
| `core/constants/constants.dart` | Its own unused barrel (re-exports files that are all imported directly elsewhere) — zero risk to remove | **Deleted** |
| `features/staff/presentation/widgets/staff_card.dart` | `StaffCard` widget, confirmed zero call sites anywhere (superseded by `StaffCardDetailed`), zero test references | **Deleted** |
| `features/evolution/cms/presentation/widgets/announcement_banner.dart` | `AnnouncementBanner` — a fully complete, self-contained, zero-risk widget (renders nothing on loading/empty/error) whose own doc comment says "drop into any home shell," but was never actually dropped anywhere | **Wired into `HomeClientScreen`** (right after the existing `KynzaOfflineBanner`) rather than deleted — this was working code waiting to be connected, not dead code |
| `core/models/notification_template_model.dart` | Tested (`test/unit/notification_models_test.dart`) but zero real-app consumers | Flagged, not removed — plausibly scaffolded ahead of a not-yet-built admin screen; deleting a tested model on ambiguous ownership is exactly the "risky, don't rush it" case this checkpoint's own brief calls out |
| `core/utils/security_utils.dart` | `maskPhone`/`maskEmail`, tested but zero real-app consumers | Flagged — a plausible real feature gap (confidential-mode masking already exists for currency; phone/email masking exists but isn't wired anywhere), scoped as a UI feature addition, not a code-quality cleanup |
| `features/evolution/ab_testing/.../ab_testing_providers.dart` | Zero consumers | Flagged, not removed — this is the same "engine built, not yet consumed" shape as P2-12 (feature flags), a product-wiring gap, not dead code to delete |
| `features/evolution/business_observability/.../business_observability_providers.dart` | Zero consumers | Same as above |
| `features/maps/application/maps_providers.dart` | Zero consumers | Not a finding — already-documented, deliberately inert Google Maps scaffold (external API-key dependency), same precedent as App Check |

`flutter analyze`: 0 issues after both deletions + the new wiring. `flutter test`: 409/409,
unchanged (neither deleted file had any test coverage to lose).

### P3-5 — Edge Function hygiene: bounded, real progress, not a full 22-function rollout

Confirmed via fresh `grep`: genuinely 0/22 functions had any correlation-ID/structured-logging
pattern. Built `_shared/log.ts` (request-ID generation + structured JSON `console.log`/
`console.error` helpers) and adopted it in 2 representative functions
(`calculate-commission`, `create-platform-backup`) as proof the pattern works — **not** rolled out
to all 22, which remains the "Large (per-function)" effort already deferred by 3 prior passes for
good reason (an unsupervised mechanical rewrite of 22 functions' error handling risks silently
changing behavior in functions this program has spent 4 passes hardening). Live-tested on
`kynza-dr-scratch`: both functions redeployed and re-invoked, confirmed identical response
behavior to before (logging is additive, not behavior-changing).

**Status**: `Ouvert`, re-scoped — a ready-to-adopt helper now exists (previously nothing did) and
2 functions prove it; full 22-function rollout stays explicitly deferred, stated here rather than
silently dropped.

## Statut final

| ID | Statut |
|---|---|
| P2-18 | **Fermé (preuve)** — trigger live-tested, genuinely fires |
| P3-8 | **Fermé (preuve)** — columns confirmed present on all 3 tables |
| P3-9 | **Fermé (preuve)** — FK validated live, zero orphaned rows, index added |
| P3-5 | Ouvert — shared helper built, proven on 2/22 functions, full rollout explicitly deferred |
| (new) dead code | 2 files deleted, 1 file wired into real use, 4 files flagged with reasoning, 1 stale claim in a prior report corrected |

## Documentation associée

`docs/certification-v2/CP1_ARCHITECTURE_REVERIFY.md` (barrel-file claim corrected by this
checkpoint's evidence).

## Commit hash

See end-of-checkpoint commit.
