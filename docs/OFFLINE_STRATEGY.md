# KYNZA — Offline-First Strategy

> Part 11. This document reports **current implemented state** vs. **target architecture**
> honestly and separately — a prior finding in this documentation effort (Phase A) established
> that `docs/ai/skills/kynza-offline-realtime.md` describes a full outbox-queue system that does
> not exist in `lib/` (verified: `hive_service.dart`, `outbox_sync_service.dart`,
> `conflict_resolver.dart`, `realtime_service.dart` all return zero matches repo-wide). This
> document does not repeat that spec as fact.
>
> **Updated 2026-07-03 (Phase 6, Enterprise Hardening pass).** An outbox now exists for real —
> first built for legal-document acceptance (Phase 3), formalized with a dead-letter queue
> (Phase 4), and generalized in this phase to review creation, profile edits, and data-deletion
> requests via a second, generic queue (`MutationOutboxService`). Booking creation remains
> deliberately unqueued — §3 below explains why, reconciling this phase's own brief (which named
> "bookings" as a target) against the reasoning already documented here before this phase started.

## 1. Objectifs

Formalize what offline support actually exists today, and specify — without overstating current
capability — what a real implementation of the target architecture would need, so this gap is
tracked as a scoped project rather than assumed-done infrastructure.

## 2. Architecture — current state (verified)

See [`docs/diagrams/offline-diagram.mermaid`](diagrams/offline-diagram.mermaid) (Part 1).

**Hive boxes, all opened in `lib/main.dart`:**

| Box | Backing class | Contents | Encrypted? |
|---|---|---|---|
| `kynza_prefs` | `SessionService` | Session persisted flag, onboarding done, role, language, confidential mode, pending invitation/referral tokens, journey dismissal, recent searches (max 10) | **Yes**, since Phase 5 — `HiveAesCipher`, key in OS Keychain/Keystore via `flutter_secure_storage` (`lib/core/services/hive_encryption_key_service.dart`) |
| `permission_cache` | `PermissionCache` | RBAC `check_permission()` results, 15-min TTL | No — booleans only, no PII of value |
| `kynza_legal_acceptance_queue` / `kynza_sync_dead_letter` | `LegalAcceptanceQueueService` | Queued legal-document acceptances (Phase 3) + their DLQ (Phase 4) | No — `userId` (UUID) + document/version IDs only |
| `kynza_mutation_outbox` / `kynza_mutation_dead_letter` | `MutationOutboxService` (**new, Phase 6**) | Queued review-creation/profile-update/data-deletion-request mutations + their shared DLQ | No — same rationale as the legal queue: IDs and form-field values, no auth secrets |

**Realtime**: every live-data screen uses `SupabaseService.client.from(table).stream(primaryKey:
['id']).eq(...)` (`docs/ARCHITECTURE_GLOBAL.md` §2.6) — this gives an in-memory "last known good"
state for as long as the screen/provider is alive, but nothing persists it to disk. On app
restart while offline, these screens have no cached data to show at all (not the same as a
disk-backed offline cache) — **unchanged by Phase 6**, which addresses write-side queueing, not
read-side caching; a disk-backed read cache remains a separate, unbuilt gap.

**ProxiPay has zero Hive usage** — it is fully online/session-based via the `proxipay_sessions`
table; there is no local queue for in-person payments either. **Unchanged by Phase 6** — payment
confirmation is money-adjacent and was out of this phase's named scope.

**What still does NOT exist, confirmed absent**: a disk-backed read cache for bookings/agenda
data (§3's "View this week's agenda" row), a queue for booking status changes
(mark-no-show/completed) or cash payment recording, and a client note queue.

## 3. Per-Flow Offline Behavior (honest gap table)

| Flow | Target (per `kynza-offline-realtime.md`) | Actual today |
|---|---|---|
| View this week's agenda | Read/write encrypted Hive cache (`agenda_j7`), fallback on reconnect | **Not implemented** — `.stream()` shows last in-memory emission only while the screen stays mounted; a fresh cold start offline shows nothing. Out of Phase 6's scope (write-queueing, not read-caching) |
| Booking creation | Client-side unavailable by nature (Edge-Function-only, atomic slot lock) — no offline queue makes sense here even in the target spec | **Deliberately still not queued — see the note below.** Phase 6's own brief named "bookings" as a target, but the reasoning already written here before Phase 6 started still holds after re-checking it: slot availability is inherently server-authoritative (no client can know a slot is free without asking), and `booking_flow_provider.dart`'s UI navigates to `PaymentScreen` using the real, server-issued `booking.id` — which doesn't exist until the write actually succeeds. Queueing the *intent* and reconciling a slot conflict on reconnect would need a different, non-navigate-immediately UX, not just a Hive box; that's a real feature redesign, not a queueing bolt-on, and was consciously kept out of this phase (Mylord's explicit decision) |
| Booking status change (mark completed/no-show) | Outbox-queued, synced on reconnect | **Not implemented** — `mark-no-show`/booking completion require network; attempting offline fails outright with no queue. Not in Phase 6's named scope either |
| Cash payment recording | Outbox-queued (`cash_payment_queue` box), synced on reconnect, priority 3 | **Not implemented** — no such Hive box exists; `calculate-commission`/`transactions` writes require network. Money-adjacent, deliberately out of Phase 6's scope |
| Client note | Outbox-queued, priority 4 | **Not implemented** |
| Review submission | Not explicitly speced in the skill doc as queueable, but implied by general offline-first intent | **Implemented (Phase 6)** — `ReviewNotifier.createReview` queues via `MutationOutboxService` when offline; `OfflineSyncCoordinator` replays on reconnect, checking `canReview()` first so a duplicate-avoided replay never even attempts a doomed insert against `reviews.booking_id UNIQUE`. Proven by test (`test/unit/offline_sync_coordinator_test.dart`), not asserted |
| Profile edit | Not explicitly speced | **Implemented (Phase 6)** — `ClientProfileNotifier.updateProfile` queues with `dedupeKey: userId` (last-write-wins: a second offline edit replaces the first queued one, never both replay). Avatar upload (binary bytes) is explicitly **not** queued — out of scope, since persisting image bytes in a Hive queue is a materially different (and heavier) problem than queuing form-field text |
| Data-deletion request (Phase 3) | Not in the original skill doc (feature didn't exist yet) | **Implemented (Phase 6)** — `DataDeletionNotifier.requestDeletion` queues when offline; the coordinator checks for an existing `pending` request before replaying, so a flaky-connection retry never creates two rows for the same user |
| Mobile Money payment | Correctly speced as **always requiring network** (non-custodial R01, no exceptions) | **Matches target** — this is correct behavior, not a gap |
| Push notifications | Correctly speced as **server-queued, never client-queued** | **Matches target** |

## 4. Conflict Resolution Policy (per entity)

| Entity | Policy | Rationale | Enforced how |
|---|---|---|---|
| Booking slots | **Server-authoritative, always** | `bookings.uq_practitioner_slot UNIQUE(practitioner_id, start_time)` already enforces this at the database level today, independent of any client queue — two offline clients could never both "win" the same slot even if a queue existed, because the constraint would reject the second INSERT server-side (surfaces as `409 slot_taken`, `docs/EDGE_FUNCTIONS_REFERENCE.md`) | DB constraint (not a client-side queue — see §3) |
| Profile edits (name, phone, email) | **Last-write-wins** | Low-stakes, no financial/scheduling impact; simplest policy that matches user expectation ("my last edit sticks") | `MutationOutboxService.enqueue(..., dedupeKey: userId)` — only the most recent queued edit survives; replaying an UPDATE is always safe since it's idempotent by nature |
| Cash payments | **Server-authoritative with manual-review fallback on repeated failure** | Per the target spec's `retryCount > 5 → flagForManualReview` pattern — money-adjacent, never silently discard | Not implemented (§3) |
| Reviews | **One review per `booking_id`, enforced server-side; the queue never even attempts a doomed duplicate** | `reviews.booking_id UNIQUE` is a hard DB constraint; `OfflineSyncCoordinator` also pre-checks `canReview()` before replaying, so "conflict" here is caught before the write is attempted, not after a failed insert | DB constraint + coordinator pre-check |
| Data-deletion requests | **At most one active (`pending`) request per user; later requests while one is pending are no-ops** | A user re-tapping "delete my data" while offline, or a flaky reconnect replaying the same intent twice, should never create duplicate rows for the support team to triage | `OfflineSyncCoordinator` checks `getUserRequests()` for an existing `pending` row before replaying |

## 5. Realtime Reconciliation

Real behavior (verified, `docs/ARCHITECTURE_GLOBAL.md` §2.6): the Supabase SDK's `RealtimeClient`
reconnects automatically with its own default backoff — no KYNZA-authored reconnect/backoff code
exists. Since there is no local outbox to reconcile against on reconnect, "reconciliation" today
is simply: the `.stream()` re-subscribes and receives a fresh snapshot, replacing whatever stale
in-memory state existed. There is no risk of duplicate inserts from a reconnect today, precisely
*because* there's no offline queue that could double-submit anything — this is a side effect of
the gap, not a solved problem.

## 6. Entity Versioning Integration

`entity_versions` (real, `docs/DATABASE_ARCHITECTURE.md` §3.10) currently versions `services` and
`invoices` only, via `AFTER INSERT/UPDATE` triggers — this is unrelated to offline conflict
resolution today (it's a general audit-trail feature, not wired to any client-side sync flow).
If an outbox/conflict-resolution system is ever built, `entity_versions` would be a natural place
to record what a conflicting local edit *would have been* for audit purposes, but this is a
**proposed integration point**, not existing behavior.

## 7. Recovery from Force-Close

**Now applicable** — both outboxes (`LegalAcceptanceQueueService`, `MutationOutboxService`) are
Hive-persisted, so a force-close doesn't lose a queued mutation: Hive writes to disk synchronously
on `enqueue()`, before the method even returns, so there's no in-memory-only window where a
force-close could drop an item. On next launch, the queue is exactly as it was left; the flush
trigger (`KynzaOfflineBanner`'s offline→online transition) fires again normally once connectivity
is confirmed, replaying whatever was still pending. This was proven at the unit level (a real
temp-directory Hive box, not a mock) for the legal queue in Phase 3/4 and for the generic
mutation outbox in Phase 6 — not asserted from the "Hive persists synchronously" claim alone.

## 8. Contraintes & Edge Cases

- Any future offline queue implementation must account for `bookings`' real
  `UNIQUE(practitioner_id, start_time)` constraint being the actual conflict boundary — not a
  new application-level lock.
- `SessionService`'s `kynza_prefs` box is unencrypted despite holding pending invitation/referral
  tokens — these are single-use, short-lived, and not directly exploitable beyond letting an
  attacker with device access complete an invitation/referral the legitimate user already
  initiated; still worth encrypting if the outbox pattern (which explicitly calls for
  `HiveAesCipher`) is ever built, for consistency.

## 9. Sécurité

See `docs/security/SECURITY_ENTERPRISE.md` (Part 12) — Hive encryption-at-rest status is
addressed there as an OWASP Mobile Top 10 item (M9/M10 data storage), not duplicated here.

## 10. Performance

An on-disk cache (if built) would directly serve Part 13's "offline mode load time <500ms"
target, which today is **unachievable** for any screen relying purely on `.stream()`'s in-memory
state, since a cold start offline has nothing to render — flagged as a real, current performance
gap in Part 13.

## 11. Stratégie de tests

The existing `docs/ai/skills/kynza-offline-realtime.md` §8 "Procédure de test offline (mode
avion)" describes a manual airplane-mode test procedure — now genuinely exercisable for review
creation, profile edits, and data-deletion requests (Phase 6), and was already exercisable for
legal-document acceptance (Phase 3/4). Automated coverage:

- `test/unit/legal_acceptance_service_test.dart` — legal-acceptance queue: offline enqueue,
  flush-on-reconnect, DLQ after 3 failed attempts.
- `test/unit/offline_sync_coordinator_test.dart` (**new, Phase 6**) — the generic mutation
  outbox: one integration test per flow (review, profile, data-deletion) proving offline enqueue
  → reconnect → **exactly one** server-side effect (not zero, not duplicated), plus one test
  proving the duplicate-avoidance pre-check actually prevents a doomed replay (not just that it
  exists in code), plus one DLQ test proving a persistently-failing item is neither lost nor
  retried forever.

No manual airplane-mode pass was additionally run in this phase — the automated tests above use
real temp-directory Hive boxes (not mocks) and fake repositories that behave exactly like the
real ones for the properties being tested (success/failure/duplicate-detection), which is a
stronger and more repeatable proof than a one-off manual toggle of the device's airplane mode.

## 12. Documentation associée

- `docs/ai/skills/kynza-offline-realtime.md` — target architecture spec (not current state).
- `docs/ARCHITECTURE_GLOBAL.md` §2.5/2.6 — offline/realtime diagrams and the original gap finding.
- `docs/PRODUCTION_CHECKLIST.md` — this gap tracked there as tech debt.
- `docs/PERFORMANCE_TARGETS.md` (Part 13) — the offline-load-time target this gap currently blocks.

## 13. Critères d'acceptation

- [x] Every mutating flow (booking, review, payment, profile edit, data-deletion) has a
  documented offline behavior — honestly reported as "not implemented" where that's still the
  truth (booking creation, cash payments, booking status changes), and "implemented, proven by
  test" where Phase 6 actually closed the gap (reviews, profile edits, data-deletion requests).
- [x] Conflict policy stated per entity type (§4), grounded in real existing DB constraints where
  they already provide the guarantee (booking slots, review uniqueness), or a real coordinator
  pre-check where Phase 6 added one (data-deletion requests, profile edit dedup).
- [x] Every previously-gapped flow this phase closed now has a passing offline→sync integration
  test (§11) — no duplicate server-side writes proven via test, not inspection.

## 14. Livrables

- `docs/OFFLINE_STRATEGY.md` (this file)
