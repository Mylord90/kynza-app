# CP5 — Tests

**Date**: 2026-07-05. **Scope**: push coverage meaningfully on the highest-risk paths, closing
P2-10's root cause (no DI/mocking seam for any repository) for at least one real, named
high-risk path (ProxiPay), rather than re-quote the old 23% figure.

## Objectifs

P2-10 (repository-layer test infrastructure).

## Preuve

### Real, measured baseline — not re-quoted

`flutter test --coverage` + a custom lcov parser (not eyeball): **26.38% overall line coverage**
(2223/8427 lines) at session start — the Master Inventory's own "23.29%" figure is now stale
(coverage genuinely grew since that report, a real improvement worth noting rather than silently
carrying the old number forward). Confirmed **20 of 24** `*_repository_impl.dart` files at
**exactly 0%** coverage — P2-10's finding re-verified accurate, not assumed.

### The missing DI/mocking seam — built and proven on a real, named high-risk repository

`ProxiPayRepositoryImpl` (explicitly named in this checkpoint's own brief as a highest-risk path)
now takes an injectable `SupabaseClient` via an optional constructor parameter
(`ProxiPayRepositoryImpl({SupabaseClient? client})`, defaulting to the real
`SupabaseService.client` — zero behavior change for the single existing call site, verified by
`grep`). This is the exact seam P2-10 says doesn't exist anywhere in this codebase.

Added `mocktail` as a dev dependency (none existed) and wrote
`test/unit/proxipay_repository_impl_test.dart` — 2 new tests, both passing, covering
`createSession`'s failure paths (non-200 Edge Function response, network exception) using a mocked
`SupabaseClient`/`FunctionsClient`.

### A real, second finding surfaced by actually trying this, not by inspection alone

Attempting to also test `confirmSession` failed with `[core/no-app] No Firebase App has been
created` — **not a mistake in the test, a real architectural fact surfaced by actually running
it**: `confirmSession` wraps its entire body in `PerformanceMonitoringService.traceAsync`, which
calls `FirebasePerformance.instance` *before* the wrapped callback runs, outside
`confirmSession`'s own try/catch. No Firebase platform-channel mocking exists anywhere in this
test suite (`grep` for `setupFirebaseCoreMocks`/`Firebase.initializeApp` across `test/`: zero
matches) — meaning **any** function wrapped in `traceAsync` is currently untestable in isolation
without new Firebase-mocking infrastructure. Scoped this checkpoint's test file to what's
actually testable (`createSession`) and documented the `confirmSession` gap directly in the test
file's own doc comment, not silently worked around.

### Coverage delta — measured before/after, not asserted

```
Before: 26.38% overall (2223/8427), 20/24 repository_impl files at 0%
After:  26.44% overall (2229/8432), 19/24 repository_impl files at 0%
```
A modest, honest delta — proportionate to what one bounded, real addition produces. The value of
this checkpoint is the **pattern now existing at all**, not a large coverage-percentage jump; a
large jump claimed from one repository's worth of tests would be the kind of overstatement this
campaign's governing rule forbids.

### What remains, stated explicitly rather than silently deferred

- 19 more `*_repository_impl.dart` files remain at 0%, same DI-seam treatment applies to each —
  genuinely "Large (per-function)"-shaped work, unchanged from 2 prior passes' own assessment that
  this can't be safely rushed in one checkpoint.
- Testing anything wrapped in `PerformanceMonitoringService.traceAsync` needs Firebase
  platform-channel mocking built first — a new, real, distinct infrastructure gap this checkpoint
  found, not previously documented anywhere.
- Concurrency/offline/RLS-adjacent test coverage is already real and substantial (the existing
  `test/live/`, `test/integration/offline_airplane_mode_test.dart`,
  `test/unit/dependency_down_resilience_test.dart`, `test/unit/cold_start_offline_cache_test.dart`
  suites) — re-confirmed present and passing this session, not re-built.

## Statut final

| ID | Statut |
|---|---|
| P2-10 | Ouvert, re-scoped — DI/mocking seam pattern established and proven on 1 named high-risk repository (ProxiPay); 19 more repositories and the Firebase-mocking gap remain, explicitly stated |

## Documentation associée

`test/unit/proxipay_repository_impl_test.dart` (new), `lib/features/proxipay/data/repositories/
proxipay_repository_impl.dart` (DI seam added).

## Commit hash

See end-of-checkpoint commit.
