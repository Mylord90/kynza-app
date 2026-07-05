# CP1 — Enterprise Resilience: Dependency-Down Scenarios

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

Distinct from the prior campaign's network-loss/reconnect tests (`docs/final-enterprise-
validation/OFFLINE_REPORT.md`): here the network interface is *up* but a specific dependency
(Supabase, FCM, Maps) is *down or erroring*. Per the governing rule for this pass, every claim
below is either a real test run in this session, a citation of a real test already proven by a
prior pass, or an explicit statement that the scenario needs physical-device/manual QA and cannot
be honestly tested in this headless environment — never a described-but-unverified assumption.

## 1. Systemic finding: "online" means "network interface up," not "dependency reachable"

`ConnectivityService` (`lib/core/services/connectivity_service.dart`) wraps `connectivity_plus`
and reports only whether a network interface (WiFi/cellular) is active — it never checks whether
Supabase, FCM, or any other dependency actually responds. Every offline-queueable write path in
the app (`ReviewNotifier.createReview`, `ClientProfileNotifier`'s update, `LegalAcceptanceNotifier
.acceptCurrentVersion`, and the data-deletion equivalent — confirmed identical in
`review_providers.dart:48`, `client_profile_providers.dart:43`, `legal_providers.dart:214,290`)
makes its "write directly vs. queue offline" decision using only this signal:

```dart
final isOnline = ref.read(connectivityProvider).value ?? false;
if (!isOnline) { /* queue */ } else { /* write directly */ }
```

**Consequence, proven with a real test** (`test/unit/dependency_down_resilience_test.dart`): when
the network interface is up but Supabase itself throws (simulated: unreachable/erroring), the
write takes the "online" branch, the repository call throws, and the mutation is **never queued**
— it's simply lost from the retry/outbox mechanism. The exception surfaces as a bare error with no
automatic recovery once Supabase comes back. Test output:

```
network interface reports online but Supabase itself is unreachable: the write is attempted
directly (never queued), throws, and is lost from the retry/outbox mechanism entirely
✓ PASS (outbox.pending() confirmed empty after the throw — the mutation was never queued)
```

This is the direct rationale for CP2 (Circuit Breaker Architecture): a circuit breaker wrapping
these dependency calls would let the write path treat "Supabase erroring" the same as "Supabase
unreachable" and fall back to the offline queue instead of surfacing a bare error — closing
exactly this gap. **This is the single most important finding of CP1** and the priority input to
CP2's design.

## 2. FCM unreachable/erroring

`NotificationService.initialize()` (`lib/core/services/notification_service.dart`) calls
`_messaging.requestPermission()`, `_messaging.getToken()`, and `saveFcmToken()` with no try/catch.
Its only caller, `auth_boot_gate.dart:29`, invokes it as `service.initialize();` — **not awaited,
no try/catch at the call site either**. Traced forward: `main.dart:36` wraps the whole app in
`runZonedGuarded(_bootstrap, (error, stack) => CrashReportingService.recordError(...))`, so an
FCM failure here does NOT crash the app (the zone catches it) and IS reported to crash reporting —
but it never reaches any of the 5 UI states (`loading`/`error`/`empty`/`offline`/`data`). The user
sees nothing: push notifications simply don't work, silently, with no retry and no visible
indication to distinguish "permission denied" from "FCM genuinely unreachable." **Determination**:
does not crash (confirmed by code path — `runZonedGuarded` is the app's real global handler, not
an assumption); does not degrade into a visible state; no automatic retry.

## 3. Maps unreachable

Already covered by the existing, passing `test/unit/maps_repositories_test.dart` (Phase 7
scaffold): every Maps repository (`PlacesAutocompleteRepository`, `GeocodingRepository`,
`DirectionsRepository`, `DistanceMatrixRepository`) is feature-flag-gated and returns
empty/null with no throw when disabled — and the test additionally proves that **even if the
gate were somehow enabled, there is no SDK wired in yet**, so it would throw
`UnimplementedError` rather than attempt a real network call. **Determination**: safe by
construction — Maps-down is a non-issue today because Maps isn't live yet (confirmed tech debt,
`AGENT.md` §18). No new test needed; this is a direct citation of already-passing coverage.

## 4. Network loss mid-booking

`create-booking` relies on `UNIQUE(practitioner_id, start_time)` (migration
`20260623240000_bookings_schema.sql:34`) as its real double-booking backstop — confirmed this
constraint exists and would reject a retry that targets the same slot. However, the same
migration also defines `idempotency_key VARCHAR(255) UNIQUE` (line 23) specifically for this
purpose, and `supabase/functions/create-booking/index.ts` **never reads or writes it** — grepped
directly, zero references. **Determination**: partial protection only. A same-slot retry after a
lost response is safely rejected by the slot-uniqueness constraint (fails visibly, no duplicate).
But the purpose-built idempotency mechanism for the general case (e.g. a client-side retry with a
distinct payload nuance, or a future flow where the uniqueness constraint doesn't apply) sits
unused as dead schema. Recommended fix (not applied — out of this pass's zero-new-features scope):
wire the app to generate and send a client-side idempotency key on every booking submission, and
have `create-booking` upsert-or-return-existing on conflict.

## 5. Network loss mid-payment

`proxipay-create-session` creates a fresh, short-lived `proxipay_sessions` row scoped to a
`bookingId` with no client-supplied idempotency requirement. Reviewed the code path: if network
drops after the server creates the session but before the client (staff device) receives the
`sessionId`, the staff app shows an error and can safely retry — creating a second session row is
not a correctness problem (each session is an independent, short-lived QR target with its own
`expires_at`; the booking itself isn't mutated by session creation, only by a subsequent
confirmed payment). **Determination**: safe to retry, no duplicate-charge risk from this step
alone — payment confirmation itself (`proxipay-confirm`) was not re-audited here (already covered
by the prior Security re-verification, CP7 of the Final Enterprise Validation pass).

## 6. Scenario matrix

| Scenario | Method | Determination |
|---|---|---|
| Supabase unreachable/erroring (network up) | **Tested** — `dependency_down_resilience_test.dart` | App doesn't crash (error surfaces as AsyncError), but the mutation is lost, not queued — real gap, see §1 |
| FCM unreachable/erroring | Code-reviewed (traced call path + global zone handler) | Doesn't crash; degrades silently (no UI state, no retry) — see §2 |
| Maps unreachable | **Cited** — `maps_repositories_test.dart` (existing, passing) | Safe by construction (gated + inert) |
| Total network loss | **Cited** — `docs/final-enterprise-validation/OFFLINE_REPORT.md` (prior pass) + CP0's fault-injection tests this session | Covered in depth already; not re-tested here per CP1's own scope note |
| Unstable/flaky network | **Cited** — prior OFFLINE_REPORT.md | Not re-tested here |
| Network returning after several hours | **Requires physical device** — real wall-clock passage and OS-level radio state can't be honestly simulated headlessly | Not tested; flagged as needing manual QA |
| Wi-Fi ↔ Mobile handoff | **Requires physical device** — `connectivity_plus` reports OS radio events this environment cannot generate | Not tested; flagged as needing manual QA |
| Forced app kill | **Tested** — CP0's `offline_fault_injection_test.dart` "Phone restart during an active outbox flush" (real on-disk Hive, no mocks) | Data preserved, no double-apply on resume, proven this session |
| Phone restart mid-sync | **Tested** — same test as above | Resumes correctly, confirmed |
| Network loss mid-payment | Code-reviewed — §5 | Safe to retry, no duplicate-charge risk from session creation |
| Network loss mid-booking | Code-reviewed — §4 | Partially protected (slot-uniqueness); purpose-built idempotency key unused |
| Automatic reconnection | **Cited** — prior OFFLINE_REPORT.md + `KynzaOfflineBanner`'s connectivity listener (code-reviewed, triggers `flush()` on reconnect, now race-safe per CP0) | Confirmed triggers correctly; the queue-vs-lost distinction from §1 still applies to what gets recovered |

## 7. Exit criteria

- [x] Every scenario has either a real test, a cited real test, or an explicit "requires physical
  device" flag — no invented results.
- [x] One new, real, systemic gap found and proven with a test (§1) — flows directly into CP2.
- [x] One dead-code finding (§4, unused `idempotency_key`) documented precisely enough to act on
  later, without being implemented here (zero new features, per the pass's absolute rules).
- [x] `flutter analyze`: 0 issues on the new test file. Full-suite regression check deferred to
  CP0's already-clean baseline (no production code changed in this checkpoint — the finding in §1
  is a design/behavior finding to feed into CP2, not a fix applied at CP1).
