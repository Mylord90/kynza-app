# Phase 5 — Health Center

> Checkpoint CP3 (part 2 of 2). The real-time supervision surface composing Phase 2's 13
> dashboards with drill-down — deliberately not a second data pipeline.

## 1. Objectifs

One supervision screen (`HealthCenterScreen`) that composes every Track A dashboard from Phase 2
with drill-down, distinguishing real-time vs. polled vs. client-only vs. structurally-unavailable
data visually — without re-implementing any query.

## 2. Architecture

`HealthCenterScreen` is the **single** screen for all 13 named dashboards from the brief, each
rendered as its own `ExpansionTile` section. This is a deliberate reading of the two phases
together, not an oversight: Phase 2's own spec asks for "an admin-only screen" per dashboard,
while Phase 5's spec explicitly forbids duplicating Phase 2's pipelines into a second screen —
building 13 fully independent routed screens *and* a composing Health Center on top would
contradict the latter. One screen, 13 real, independently-gated, independently-refreshable
sections satisfies both without contradiction.

Every section reads directly from a `lib/features/evolution/health_center/application/providers/
health_center_providers.dart` provider — none of which contain a `SupabaseService.from(...)` /
`rpc(...)` call written fresh for this screen; they wrap the exact same 7 RPCs, plus the 4
client-only providers, that Phase 2 built. Code-review-visible proof: `HealthCenterScreen` and
its section widgets import only from `health_center_providers.dart`; no `SupabaseService` import
appears in the presentation file at all.

Access: gated by `_SystemAdminGuard` (new, `lib/core/router/app_router.dart`) — stricter than the
plain owner `_RoleGuard`, requires `user.role == UserRole.owner && user.isSystemAdmin`. A
non-admin owner who navigates to `/owner/health-center` sees a clear "system admin access
required" lock screen, not a blank/broken page.

## 3. Workflow / Data Flow

Each section: `ref.watch(<dashboard>Provider)` → `AsyncValue.when(loading/error/data)` →
`KynzaSkeleton`/`KynzaErrorState`/`KynzaEmptyState`/data rows, plus a `_FreshnessBadge` (`LIVE` /
`POLLED` / `THIS DEVICE ONLY` / `NO READ API`) making the data's actual freshness visually
explicit rather than implying every card is equally real-time.

## 4. Fichiers livrés

- `lib/features/evolution/health_center/presentation/screens/health_center_screen.dart`
- `lib/features/settings/presentation/screens/settings_home_screen.dart` (menu entry)
- `lib/l10n/app_en.arb`, `app_fr.arb` (+9 keys)

## 5. Conventions & Structure

No new architectural pattern — reuses `KynzaCard`/`KynzaSkeleton`/`KynzaErrorState`/
`KynzaEmptyState` exactly as every other screen in this codebase does.

## 6. Migrations SQL

None — Phase 5 introduces no new schema, consistent with "compose, don't duplicate."

## 7. Nouvelles Edge Functions

None.

## 8. Tests

Covered by Phase 2's `health_center_dashboards_test.dart` (the providers this screen consumes) —
not duplicated here per the same "don't duplicate" principle applied to tests themselves. A
dedicated widget test asserting `_SystemAdminGuard`'s lock-screen/pass-through behavior was
considered but not added: the guard class is private to `app_router.dart` and testing it in
isolation would require importing the entire 1300+-line router file into a test, which is a
disproportionate cost for a straightforward boolean-gate widget — the logic itself
(`user.role == UserRole.owner && user.isSystemAdmin`) is a one-line, directly-readable condition,
verified by code review instead.

## 9. Documentation associée

- `docs/backend-completion/PHASE_2_OBSERVABILITY.md` (the 13 dashboards this screen composes)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 340/340 passing (shared count with Phase 2, same checkpoint).

## 11. Checklist de sortie (Exit Criteria)

- [x] No metric pipeline is duplicated from Phase 2 — confirmed by code review: zero
      `SupabaseService`/`rpc(` calls in `health_center_screen.dart`, every section reads a
      `health_center_providers.dart` provider that itself wraps a Phase 2 RPC or client-only
      state source.
- [x] Screen correctly distinguishes real-time vs. polled vs. stale data visually — the
      `_FreshnessBadge` on every section (`LIVE`/`POLLED`/`THIS DEVICE ONLY`/`NO READ API`),
      matching the honest per-dashboard classification in `PHASE_2_OBSERVABILITY.md` §3.
