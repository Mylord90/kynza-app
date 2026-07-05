# CP1 — Architecture Backend

**Date**: 2026-07-05. **Scope**: close every Master Inventory row under Architecture (P3-1, P3-2,
P3-3, P3-4), re-verify SOLID/Clean layering with fresh tool output, not re-derive from scratch.

## Objectifs (Master Inventory rows this closes)

P3-1 (circular provider dependencies — target: **closed for real**), P3-2 (repository-layer
bypass), P3-3 (repository/datasource split), P3-4 (router monolith).

## Preuve

### P3-1 — 2 real circular dependencies, fixed and tool-verified closed

Wrote a fresh Node.js DFS import-cycle detector (same method as `CP1_ARCHITECTURE_REVERIFY.md`,
independently re-implemented, not reused code) over all 450 non-generated `lib/` files.
**Before the fix**: confirmed via direct import inspection the 2 real cycles still existed exactly
as documented:
- `core/providers/auth_providers.dart` <-> `features/auth/application/notifiers/auth_notifier.dart`
  (core imported `AuthNotifier`/`AuthUiState` for `authNotifierProvider`; the notifier imports core
  right back for `authStateStreamProvider`/`currentUserProfileProvider`).
- `core/providers/offline_sync_providers.dart` <-> 3 feature provider files
  (`client_profile_providers.dart`, `legal_providers.dart`, `review_providers.dart` — each imported
  back for `mutationOutboxServiceProvider`, while core imported them for their repository
  providers to build `offlineSyncCoordinatorProvider`).

**Fix**: split each core file in two. `authNotifierProvider` moved to a new,
feature-owned file (`features/auth/application/providers/auth_notifier_provider.dart`);
`offlineSyncCoordinatorProvider` moved to a new core-composition file
(`core/providers/offline_sync_coordinator_provider.dart`) that no feature imports back — only the
one shared widget that actually needs it (`kynza_offline_banner.dart`) does. 14 consumer files
across `core/router`, `core/widgets`, and 5 feature areas updated to import from the new
locations. `mutationOutboxServiceProvider`/`authStateStreamProvider`/`currentUserProfileProvider`
stayed exactly where they were — zero behavior change, only import-graph topology changed.

**After the fix**, same detector re-run: **0 real cycles found** — only the 2 pre-existing benign
generated-code cycles remain (`l10n/app_localizations.dart` <-> `_en.dart`/`_fr.dart`, standard
`flutter gen-l10n` pattern, not authored code).

```
Scanned 450 non-generated files in lib/.
Found 2 cycle(s):
  l10n/app_localizations.dart -> l10n/app_localizations_en.dart -> l10n/app_localizations.dart
  l10n/app_localizations.dart -> l10n/app_localizations_fr.dart -> l10n/app_localizations.dart
```

`flutter analyze`: 0 issues. `flutter test`: 409/409 passed (unchanged — pure import
reorganization, no behavior touched, no test added/removed for this specific item).

### P3-2 / P3-3 — repository-layer bypass, re-confirmed with fresh evidence, deliberately not mass-refactored

Fresh `grep` this session (not copied from a prior report) confirms **exactly 14 presentation
files** still call `SupabaseService` directly — the same count the Master Inventory cites, now
re-verified file-by-file with the actual call site shown, not just counted:
`auth/reset_password_screen.dart`, `home_client/client_profile_screen.dart`,
`home_owner/home_owner_screen.dart`, `home_staff/home_staff_screen.dart`,
`loyalty/loyalty_scan_screen.dart`, `marketing/loyalty_setup_screen.dart`,
`marketing/marketing_dashboard_screen.dart`, `payment/payment_screen.dart`,
`referral/referral_claim_screen.dart`, `reviews/owner_reviews_screen.dart`,
`reviews/salon_reviews_tab.dart`, `staff/accept_invitation_screen.dart`,
`staff/my_performance_screen.dart`, `staff/staff_detail_screen.dart`. Most of these are genuine
ad hoc `.from('table').select()`/`.rpc()` calls embedded directly in a screen-level Riverpod
provider, not routed through the feature's own repository (confirming P3-2's finding is real, not
stale).

**Deliberately not force-fixed this pass**: moving all 14 files' live data-fetching logic into
repositories is the exact "Large" effort already assessed and deferred by 3 prior passes
(`PHASE_1_FINAL_AUDIT.md`, `MASTER_ISSUES_MATRIX.md` P3-2/P3-3, `CP1_ARCHITECTURE_REVERIFY.md`),
consistently rated Low severity ("compiles/works, maintainability debt only"). Given this
campaign's own absolute rule ("no cosmetic refactor without a cited defect" — the inverse also
holds: a cited-but-low-severity defect doesn't justify a high-risk refactor touching 14 live
screens' core data paths, several of them owner/staff dashboards with no dedicated test coverage
today to catch a regression), and given the remaining 10 checkpoints in this campaign have
higher-value, lower-risk items still open, this is re-confirmed `Ouvert` with the same reasoning
the prior 3 passes already reached — not silently dropped, not force-fixed under time pressure.

**Status**: `Ouvert`, reconfirmed with fresh file-level evidence (not stale), reasoning for
non-closure stated explicitly.

### P3-4 — router monolith, re-confirmed, explicitly out of this campaign's scope

`core/router/app_router.dart` re-measured: still 1,418+ lines (grew slightly from the P3-1 import
fix's +1 line). This item is already tracked in a dedicated, separately-scoped backlog
(`project_shellroute_refactor_backlog` per prior-session memory) — a full `ShellRoute` migration
is explicitly deferred there with its own trigger condition, not something this campaign
re-litigates. **Status**: `Ouvert`, unchanged, cross-referenced to its existing dedicated backlog.

### SOLID/Clean layering — re-verified fresh, not re-quoted

Re-ran the domain/data layer-boundary check for the same 3 features `CP1_ARCHITECTURE_REVERIFY.md`
traced (booking, loyalty, billing) with fresh `grep` this session:
```
booking domain imports:  only core/enums, core/models  (clean)
booking data layer:      0 matches for application/|presentation/  (clean)
loyalty data layer:      0 matches for application/|presentation/  (clean)
billing data layer:      0 matches for application/|presentation/  (clean)
```
Holds unchanged. No DDD bounded-context proposal made — no real coupling problem was found beyond
the now-fixed P3-1 cycles; introducing bounded contexts without a cited coupling defect would
itself be exactly the "default recommendation" this checkpoint's own brief says not to make.

## Statut final

| ID | Statut |
|---|---|
| P3-1 | **Fermé (preuve)** — real fix, tool-verified before/after, 0 regressions |
| P3-2 | Ouvert — reconfirmed with fresh evidence, reasoned non-closure |
| P3-3 | Ouvert — reconfirmed with fresh evidence, reasoned non-closure |
| P3-4 | Ouvert — reconfirmed, out of scope (dedicated backlog exists) |

## Documentation associée

`docs/certification-v2/CP1_ARCHITECTURE_REVERIFY.md` (original finding), this document (re-test +
fix evidence).

## Commit hash

See end-of-checkpoint commit (this file is committed together with the P3-1 code fix).
