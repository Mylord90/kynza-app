# CP2 — Circuit Breaker Architecture

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

## 0. Did a real circuit breaker exist before this checkpoint?

Audited every network call site (Supabase repositories, FCM registration, the `send-notification`
Edge Function's best-effort channel loop). **Answer: no** — no circuit breaker of any kind existed
anywhere in the codebase before this checkpoint. The closest things: `send-notification` already
treats each channel (push/whatsapp) as independent best-effort (a failed FCM send doesn't block
the WhatsApp send or the `in_app` log row), and `NotificationService`'s doc comment already stated
"push notifications require the network by nature — never queued client-side" — both reasonable
design calls, but neither is a breaker (no state machine, no fail-fast, no automatic recovery
test).

## 1. Design

New reusable component: `lib/core/services/circuit_breaker.dart` (`CircuitBreaker` class, `enum
CircuitBreakerState { closed, open, halfOpen }`).

- **`closed`** — calls go through normally; a run of `failureThreshold` (default 5) consecutive
  failures trips it to `open`.
- **`open`** — `run()` skips the call entirely and goes straight to `fallback` (fail fast, don't
  keep hammering a dependency that's already known to be down). After `openDuration` (default
  30s) elapses, the *next* call transitions to `halfOpen` to test recovery.
- **`halfOpen`** — the call is attempted for real; `halfOpenSuccessThreshold` (default 2)
  consecutive successes closes the breaker again; a single failure re-opens it immediately.

**Deliberate design choice, direct fix for CP1's finding**: `run(action, fallback)` invokes
`fallback` on *any* failure of `action` — not only when the breaker is already `open`. CP1
(`docs/enterprise-resilience/RESILIENCE_REPORT.md` §1) found that every offline-queueable write
treated a Supabase failure as a bare, unrecoverable error instead of falling back to the offline
queue it would have used if it had known ahead of time that Supabase was down. Since the "queue it
for later" fallback is always safe for these specific writes, there's no reason to wait for
`failureThreshold` failures before doing the safe thing — the breaker's state machine is what lets
`run()` skip a doomed network call entirely once failures have accumulated (avoiding real
timeouts, avoiding hammering a struggling backend), while *every* failure, sustained or not, gets
the same graceful degradation.

## 2. Wiring — the riskiest calls CP1 identified

`DependencyCircuitBreakers` (same file) holds one named, app-wide instance per dependency —
`supabase` and `fcm`, per CP2's own priority list. A single shared instance per dependency (not
one per call site) means a run of failures in one write path (e.g. review creation) also protects
the next one (e.g. profile update) from hammering the same down dependency.

Wired into every write path CP1 flagged, replacing the direct online-branch call with
`DependencyCircuitBreakers.supabase.run(action, fallback: enqueue)`:

- `ReviewNotifier.createReview` (`review_providers.dart`)
- `ClientProfileNotifier.updateProfile` (`client_profile_providers.dart`)
- `LegalAcceptanceService.acceptVersion` (`legal_acceptance_service.dart`) — this one centralizes
  the online/offline branch inside the service itself (unlike the other three, which branch in
  the provider), so the wiring lives there instead
- `DataDeletionNotifier.requestDeletion` (`legal_providers.dart`)

And on FCM, per "Supabase, FCM at minimum":

- `NotificationService.initialize()` — `_messaging.getToken()` now goes through
  `DependencyCircuitBreakers.fcm`, falling back to `null` (skip token save this session) instead of
  letting the failure propagate as an **unhandled exception from a fire-and-forget call** (its only
  caller, `auth_boot_gate.dart:29`, calls `service.initialize()` with no `await` and no try/catch —
  confirmed by reading the call site). The whole method is now wrapped in try/catch reporting to
  `CrashReportingService`, so a down/erroring FCM degrades to "push isn't available this session"
  instead of relying solely on `main.dart`'s global `runZonedGuarded` handler to avoid an unhandled
  rejection.
- `NotificationService.saveFcmToken()` — the Supabase `users.fcm_token` write now goes through
  `DependencyCircuitBreakers.supabase`, falling back to a documented no-op (there's nothing to
  queue: the next token refresh or the next login's `initialize()` call retries naturally).

## 3. Evidence

### 3a. State machine — `test/unit/circuit_breaker_test.dart` (7 tests, all passing)

Directly proves the transition CP2 requires:

```
✓ starts closed and stays closed while calls succeed
✓ trips OPEN after failureThreshold consecutive failures
✓ while OPEN, action is never invoked — goes straight to fallback
✓ OPEN -> HALF_OPEN -> CLOSED: after openDuration elapses, calls are attempted again;
  enough consecutive successes closes the breaker
✓ HALF_OPEN -> OPEN: a single failure while testing recovery re-opens immediately
✓ reset() forces a clean CLOSED state
✓ run() never throws when action fails — fallback absorbs it
```

The `OPEN -> HALF_OPEN -> CLOSED` test is a real integration test of the full cycle: trips the
breaker with a failing call, waits out a real `Duration` for `openDuration` to elapse, confirms the
state read lazily advances to `halfOpen`, then drives it through `halfOpenSuccessThreshold`
successful calls back to `closed` — not a mocked/assumed transition.

### 3b. The write-path fix, proven by re-running CP1's own test

`test/unit/dependency_down_resilience_test.dart` — the exact test CP1 wrote to prove the gap now
proves the fix instead (updated in place, with the original finding preserved in its doc comment
for the historical record):

```
Before CP2: throws, outbox.pending() == [] (mutation lost)
After CP2:  no throw, outbox.pending() == [the review] (mutation safely queued for retry)
```

### 3c. Full regression check

`flutter analyze`: 0 issues. `flutter test`: 402 passed, 0 failed, 5 skipped (pre-existing,
unrelated) — up from CP1's 395 total by the 7 new `circuit_breaker_test.dart` cases (the
dependency-down test count is unchanged, just its assertion flipped to prove the fix).

## 4. What's still open (honest scope boundary)

- Read paths (`FutureProvider`s backing list/detail screens) were not touched — they already
  degrade to `KynzaErrorState` (a retry-capable, non-crashing UI state) on any exception, satisfying
  "never crashes, always one of the 5 states" without needing a breaker; adding one there would be
  a pure latency/backend-load optimization (skip a doomed call, show cached data faster), not a
  correctness fix, and is left for a future pass if the cache layer (CP3) grows a read-through
  cache that a breaker could fall back to.
- `send-notification`'s per-channel best-effort sends were not wrapped — they already don't throw
  (each channel's failure is caught and logged as `delivered:false` in `notification_logs`,
  confirmed by reading the function), so there's no bare-error gap to close there; a breaker would
  only add "stop trying FCM for a while after N failures," a load-shedding optimization rather than
  a correctness fix, and is left for a future pass.

## 5. Exit criteria

- [x] Honest answer on whether a circuit breaker existed before this pass: no.
- [x] Design: `CLOSED`/`OPEN`/`HALF_OPEN`, failure threshold, timeout, recovery timeout, fallback —
  all present in `CircuitBreaker`.
- [x] Automatic degradation that never crashes the UI: the 4 write paths now fall back to the
  offline queue (one of the app's existing safe states) instead of a bare, unrecoverable error.
- [x] Wired onto the riskiest calls CP1 identified — Supabase (4 write paths) and FCM (both call
  sites in `NotificationService`).
- [x] At least one real integration test proving `OPEN → HALF_OPEN → CLOSED` — `circuit_breaker_
  test.dart`'s dedicated test, using a real elapsed `Duration`, not a mocked clock.
- [x] `flutter analyze`: 0 issues. `flutter test`: 402 passed / 0 failed / 5 skipped (pre-existing).
