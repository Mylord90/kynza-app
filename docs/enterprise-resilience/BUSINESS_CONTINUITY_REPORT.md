# CP5 — Business Continuity: Degraded-Mode Capability Matrix

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

Uses CP0's fault-injection test infrastructure (real temp-directory Hive boxes, no mocks) and
CP1's dependency-down findings directly — this checkpoint's job is to state, precisely and per
feature, what still works during an incident (network down, or a specific dependency down while
network is up).

## 1. Root architectural fact behind most of this matrix

Every mutating flow that got offline-queue support (Phase 6 of the Enterprise Hardening pass, and
CP0/CP2 of this pass) has one; **no read path has a disk-backed cache** — confirmed today by
grepping every provider file backing agenda/booking-history/catalog/profile screens
(`booking_providers.dart`, `search_providers.dart`, `client_profile_providers.dart`): every one of
them is a plain `FutureProvider`/`StreamProvider` with zero Hive reads. This was already documented
honestly in `docs/OFFLINE_STRATEGY.md` §2-3 for the agenda screen specifically; today's re-check
confirms the same is true for catalog browsing, booking history, and profile viewing — it's a
single systemic gap (no read-through cache anywhere), not four separate ones.

Practical consequence, stated once here instead of repeated per row: any read screen shows
**last-known-good data for as long as its provider stays alive in memory** (e.g., you were already
looking at your bookings when the network dropped), but **a cold app start while offline shows
nothing** for any of these screens — there is nothing on disk to hydrate from.

## 2. The matrix

| Feature | Available offline? | Why |
|---|---|---|
| **Offline booking creation** | **No** (by design, not a gap) | Slot availability is inherently server-authoritative — no client can know a slot is free without asking — and the booking flow navigates to `PaymentScreen` using the real server-issued `booking.id`, which doesn't exist until the write succeeds. A conscious, documented decision (`OFFLINE_STRATEGY.md` §3), not an oversight. |
| **Offline payment (ProxiPay)** | **No** | Confirmed zero Hive usage anywhere in the ProxiPay flow — fully online/session-based via `proxipay_sessions`. Money-adjacent, correctly never queued. |
| **Mobile Money payment (Leapa)** | **No** | Correctly speced and implemented as always-network (non-custodial, no exceptions) — matches target, not a gap. |
| **Review submission (delayed sync)** | **Yes** | Queues via `MutationOutboxService` offline; replays on reconnect, pre-checking `canReview()` so a duplicate-avoided replay never attempts a doomed insert. Proven by test pre-existing this pass, and now proven **concurrency-safe** (CP0) and **resilient to Supabase-erroring-while-online** (CP2's circuit breaker fallback) — strictly stronger than when `OFFLINE_STRATEGY.md` was last written. |
| **Profile edit (delayed sync)** | **Yes** | Queues with `dedupeKey: userId` (last-write-wins). Same CP0/CP2 strengthening applies. Avatar upload specifically is **not** queued (binary bytes, explicitly out of scope) — partial within this row. |
| **Legal document acceptance (delayed sync)** | **Yes** | Same pattern, oldest of the four queues (Phase 3/4). Same CP0/CP2 strengthening applies (this pass found and fixed its own double-flush bug, see CP0). |
| **Data-deletion request (delayed sync)** | **Yes** | Queues offline; coordinator checks for an existing `pending` request before replaying. Now additionally backstopped by a DB-level unique partial index (CP0 §5) as defense in depth. |
| **Appointment/planning consultation (agenda)** | **Partial** | Shows last in-memory snapshot while the screen stays mounted through a connectivity drop; a cold start offline shows nothing (no disk-backed cache exists — confirmed, `OFFLINE_STRATEGY.md` §3, re-verified unchanged today). |
| **Catalog browsing (salon/service search)** | **Partial** | Same shape as agenda consultation — `search_providers.dart` is a plain `FutureProvider.autoDispose`, no persistence. Already-loaded results remain visible until the provider is disposed; nothing survives a cold start offline. |
| **Profile access (viewing own profile)** | **Partial** | Same shape again — `client_profile_providers.dart`'s read side has no Hive mirror (only the *write* side queues). `SessionService`'s `kynza_prefs` box holds role/language/preferences, not the profile fields themselves (name/phone/email), so it can't serve as a fallback here. |
| **Local history (notifications, past activity)** | **Partial** | Same systemic gap — `notification_logs` reads are live-only, no disk mirror. Already-fetched history remains visible in memory until the screen/provider is disposed. |
| **Push notifications** | **No** (by design, not a gap) | Correctly speced and implemented as server-queued, never client-queued — matches target. |

## 3. Manual intervention required?

For every "Yes" row (the 4 queued mutation types): **no** manual intervention — `KynzaOfflineBanner`
triggers the flush automatically on reconnect, and CP0 made that flush safe against being triggered
by more than one of its ~40 mounted instances at once. For every "No"/"Partial" row: the user must
simply wait for connectivity (no queue exists to replay), and for the cold-start read-cache gap
specifically, reopening the app once online is what recovers the view — there's no broken state to
manually fix, just an absence of an offline view.

## 4. Does the app ever crash instead of degrading?

No crash path was found in this pass's review of any of these flows — every "No"/"Partial" read
path either shows its existing in-memory data or (on a fresh/cold provider) resolves to Riverpod's
own loading/error states, landing in one of the app's 5 UI states rather than an unhandled
exception. This is consistent with, and reuses, CP1's finding that read paths already degrade via
`KynzaErrorState` (retry-capable, non-crashing).

## 5. Exit criteria

- [x] Exact yes/no/partial matrix produced for every feature CP5 named, plus the 4 queued-mutation
  flows this pass's own fault-injection tests (CP0) directly cover.
- [x] Root cause identified as one systemic gap (no read-through disk cache) rather than
  duplicated per-feature, avoiding overstating the number of distinct problems.
- [x] Manual-intervention question answered per category, not per row (same answer within each
  category, stated once).
- [x] No invented crash scenarios — confirmed via code review that read-path failures land in an
  existing UI state, not a crash, consistent with CP1's finding.
