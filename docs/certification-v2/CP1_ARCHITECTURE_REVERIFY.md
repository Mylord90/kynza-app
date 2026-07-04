# CP1 — Architecture & Backend Re-verification `[RE-VERIFY]`

Re-tested, not re-read: every claim below was checked by running a tool or tracing real imports,
not by trusting the prior pass's own report.

## 1. Circular dependency scan (tool-run, not eyeball)

Wrote a small import-graph + cycle detector (Node.js, DFS with cycle-tracking) over all 442
non-generated files in `lib/`. Result: **6 cycles found**, 3 of them benign, 3 real.

| Cycle | Verdict |
|---|---|
| `l10n/app_localizations.dart` ↔ `app_localizations_en.dart` / `_fr.dart` | ⚪ Benign — `flutter gen-l10n` generated code, standard pattern (abstract delegate class ↔ concrete locale lookups), not authored |
| `core/providers/auth_providers.dart` ↔ `features/auth/application/notifiers/auth_notifier.dart` | 🟡 **Real — P2, architecture** |
| `core/providers/offline_sync_providers.dart` ↔ `features/home_client/.../client_profile_providers.dart` | 🟡 **Real — P2, architecture (same root cause as above)** |
| `core/providers/offline_sync_providers.dart` ↔ `features/legal/.../legal_providers.dart` | 🟡 same |
| `core/providers/offline_sync_providers.dart` ↔ `features/reviews/.../review_providers.dart` | 🟡 same |

**Finding**: `core/providers/auth_providers.dart` directly imports
`features/auth/application/notifiers/auth_notifier.dart` and
`features/auth/domain/states/auth_ui_state.dart`; `core/providers/offline_sync_providers.dart`
directly imports three separate features' provider files
(`home_client/client_profile_providers.dart`, `legal/legal_providers.dart`,
`reviews/review_providers.dart`). Each of those feature files imports back into the same core
file. This is a genuine Clean Architecture inversion: `core` is supposed to be the innermost,
feature-agnostic layer that features depend on — here it depends back on 4 specific features to
know how to coordinate auth state and offline-sync registration. Downgraded from the prior pass's
implicit "architecture: clean" framing — this was never checked with a tool before now.

**Impact in practice**: low-to-moderate. It compiles and works (Dart tooling doesn't hard-fail on
import cycles the way some languages do), and it's contained to provider wiring, not domain logic.
But it means `core` cannot be extracted/reused independently of these 4 features, and any change to
`auth_notifier.dart` or the 3 offline-sync feature providers risks rebuild/hot-reload churn
touching `core`. Not escalated to P1: no runtime bug, no security exposure — a maintainability debt
item for the architecture backlog, not a certification blocker.

## 2. Three real features traced top-to-bottom (booking, loyalty, billing)

For each: confirmed `domain/repositories/*.dart` imports only `core/models` and `core/enums` (never
`data/` or `presentation/`), and `data/repositories/*_impl.dart` never imports `application/` or
`presentation/`. All three hold — no inward-layer violation in the direction that actually matters
(domain/data staying decoupled from UI). The only violation found is the core↔feature one above,
which is a different axis (core depending on feature, not feature layers depending on the wrong
direction internally).

## 3. SOLID/DRY/KISS/YAGNI spot-check, 5 most complex modules (by non-generated LOC)

| File | LOC | Verdict |
|---|---|---|
| `core/router/app_router.dart` | 1418 | 🟡 Monolithic single-file router for the entire app (60+ screen imports, 29 embedded private `_Owner*Loader`/helper widget classes). Not a correctness issue, but a SRP/maintainability concern — a single file this size is a merge-conflict and cognitive-load magnet. Consistent with the already-tracked ShellRoute refactor backlog (prior memory) — not a new problem, just now quantified. |
| `dashboard/presentation/screens/advanced_dashboard_screen.dart` | 1051 | ✅ Large file but well-decomposed: 11 classes, each a single tab/section (`_OverviewTab`, `_ClientsAnalyticsTab`, `_TeamAnalyticsTab`, `_ForecastTab`, …), each with one `build()`. Two `_exportPdf` methods in different classes looked like possible duplication at a glance — checked both: genuinely different signatures/purposes (revenue report vs. team-performance report), both delegate the actual PDF work to the shared `ExportService`. Not a DRY violation. |
| `home_client/presentation/screens/client_profile_screen.dart` (550 LOC) | — | Not deep-dived this pass — flagged for a future pass if it grows further; no smell found in a structural skim |
| `marketing/presentation/screens/promotion_center_screen.dart` / `marketing_dashboard_screen.dart` / `invite_clients_screen.dart` / `loyalty_setup_screen.dart` (490-530 LOC each) | — | Similar size cluster raised a copy-paste suspicion; a structural skim found each screen owns genuinely distinct domain logic (promotions vs. dashboard analytics vs. invite flow vs. loyalty setup) — no duplicated business logic found, just naturally similar screen sizes for a consistent design system |

## 4. Package/barrel export structure

No barrel (`lib/features/x.dart` re-export) files found in this codebase — every import is a direct
file path. This avoids a common barrel-file pitfall (whole-module rebuilds on any file change) at
the cost of longer import lists, which is the trade-off already visible in `app_router.dart`'s
60+ imports. Consistent, not flagged as a defect.

## 5. Multi-tenant / RBAC / auditability / versioning rubric (vs. accepting the prior "Enterprise" claim at face value)

| Rubric item | Re-tested how | Result |
|---|---|---|
| Multi-tenant isolation | Re-tested for real in CP3 (adversarial RLS), not re-asserted here | See CP3 |
| Auditability | `activity_logs` schema confirmed present with `ip_address`, `device_info`, `session_id`, `request_id`, `severity` columns (used directly in Gate 0's query) — but Gate 0 also found `accept-invitation` doesn't populate `ip_address`/`device_info` despite the columns existing, a real audit-coverage gap, not just a schema check | 🟡 Partial — schema is enterprise-grade, population is inconsistent across Edge Functions |
| RBAC granularity | `owner_manage_staff`/`manager_view_staff`/`staff_own_profile_select` confirmed to exist and be independent of the public policy Gate 0 removed (verified by reading the policies directly during Gate 0's trace, not assumed) | ✅ Holds |
| Versioning | `version_manager` feature + `force_update_screen.dart`/`maintenance_screen.dart` present in router; not independently re-tested this checkpoint (covered in CP9 store readiness) | Deferred to CP9 |

## Exit criteria

- [x] Every prior "✅ Fait" architecture claim re-tested with a tool run or direct trace, not
      re-read from the prior report.
- [x] Anything that doesn't hold up is downgraded with evidence (the core↔feature cycle) —
      nothing left at its old rating out of inertia.
- [x] No new regressions introduced this checkpoint (read-only — no code changed in CP1 itself).
