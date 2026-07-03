# KYNZA — Offline-First Strategy

> Part 11. This document reports **current implemented state** vs. **target architecture**
> honestly and separately — a prior finding in this documentation effort (Phase A) established
> that `docs/ai/skills/kynza-offline-realtime.md` describes a full outbox-queue system that does
> not exist in `lib/` (verified: `hive_service.dart`, `outbox_sync_service.dart`,
> `conflict_resolver.dart`, `realtime_service.dart` all return zero matches repo-wide). This
> document does not repeat that spec as fact.

## 1. Objectifs

Formalize what offline support actually exists today, and specify — without overstating current
capability — what a real implementation of the target architecture would need, so this gap is
tracked as a scoped project rather than assumed-done infrastructure.

## 2. Architecture — current state (verified)

See [`docs/diagrams/offline-diagram.mermaid`](diagrams/offline-diagram.mermaid) (Part 1).

**Two Hive boxes exist, opened in `lib/main.dart`:**

| Box | Backing class | Contents | Encrypted? |
|---|---|---|---|
| `kynza_prefs` | `SessionService` | Session persisted flag, onboarding done, role, language, confidential mode, pending invitation/referral tokens, journey dismissal, recent searches (max 10) | **No** — no `HiveAesCipher` in use anywhere in the codebase |
| `permission_cache` | `PermissionCache` | RBAC `check_permission()` results, 15-min TTL | **No** |

**Realtime**: every live-data screen uses `SupabaseService.client.from(table).stream(primaryKey:
['id']).eq(...)` (`docs/ARCHITECTURE_GLOBAL.md` §2.6) — this gives an in-memory "last known good"
state for as long as the screen/provider is alive, but nothing persists it to disk. On app
restart while offline, these screens have no cached data to show at all (not the same as a
disk-backed offline cache).

**ProxiPay has zero Hive usage** — it is fully online/session-based via the `proxipay_sessions`
table; there is no local queue for in-person payments either.

**What does NOT exist, confirmed absent**: an outbox/write queue of any kind, a conflict
resolver, an encrypted read/write local cache for bookings or client data, and any mechanism to
queue a mutating action (new booking, review, cash payment, profile edit) while offline for later
replay.

## 3. Per-Flow Offline Behavior (honest gap table)

| Flow | Target (per `kynza-offline-realtime.md`) | Actual today |
|---|---|---|
| View this week's agenda | Read/write encrypted Hive cache (`agenda_j7`), fallback on reconnect | **Not implemented** — `.stream()` shows last in-memory emission only while the screen stays mounted; a fresh cold start offline shows nothing |
| Booking creation | Client-side unavailable by nature (Edge-Function-only, atomic slot lock) — no offline queue makes sense here even in the target spec | **Matches target already** — this one was never meant to be queueable; `create-booking` requires network by design (server-authoritative slot lock) |
| Booking status change (mark completed/no-show) | Outbox-queued, synced on reconnect | **Not implemented** — `mark-no-show`/booking completion require network; attempting offline fails outright with no queue |
| Cash payment recording | Outbox-queued (`cash_payment_queue` box), synced on reconnect, priority 3 | **Not implemented** — no such Hive box exists; `calculate-commission`/`transactions` writes require network |
| Client note | Outbox-queued, priority 4 | **Not implemented** |
| Review submission | Not explicitly speced in the skill doc as queueable, but implied by general offline-first intent | **Not implemented** — `reviews` INSERT requires network, no draft queue |
| Profile edit | Not explicitly speced | **Not implemented** — direct `.update()` calls require network |
| Mobile Money payment | Correctly speced as **always requiring network** (non-custodial R01, no exceptions) | **Matches target** — this is correct behavior, not a gap |
| Push notifications | Correctly speced as **server-queued, never client-queued** | **Matches target** |

## 4. Conflict Resolution Policy (per entity — target design, since no queue exists to conflict yet)

| Entity | Policy | Rationale |
|---|---|---|
| Booking slots | **Server-authoritative, always** | `bookings.uq_practitioner_slot UNIQUE(practitioner_id, start_time)` already enforces this at the database level today, independent of any client queue — two offline clients could never both "win" the same slot even if a queue existed, because the constraint would reject the second INSERT server-side (surfaces as `409 slot_taken`, `docs/EDGE_FUNCTIONS_REFERENCE.md`) |
| Profile edits (name, avatar, preferences) | **Last-write-wins** | Low-stakes, no financial/scheduling impact; simplest policy that matches user expectation ("my last edit sticks") |
| Cash payments | **Server-authoritative with manual-review fallback on repeated failure** | Per the target spec's `retryCount > 5 → flagForManualReview` pattern — money-adjacent, never silently discard |
| Reviews | **Last-write-wins on the review body; server rejects a second review for the same `booking_id`** (already enforced today via the real `reviews.booking_id UNIQUE` constraint) | One review per booking is already a hard DB constraint, so "conflict" here can only be a duplicate-submission race, not a content conflict |

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

Not applicable today — since no outbox queue exists, there's nothing to lose on a force-close
beyond in-memory Realtime state (which reloads fresh from Supabase on next launch, when online).
If an outbox is ever implemented, it must be Hive-persisted (survives force-close by construction,
since Hive writes to disk immediately) — matching the target spec's existing design intent.

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
avion)" describes a manual airplane-mode test procedure — real and reusable if an outbox is ever
built, but currently untestable against nothing (there's no outbox to test). No automated offline
tests exist in the 244-test suite (none would be meaningful without an implementation to test).

## 12. Documentation associée

- `docs/ai/skills/kynza-offline-realtime.md` — target architecture spec (not current state).
- `docs/ARCHITECTURE_GLOBAL.md` §2.5/2.6 — offline/realtime diagrams and the original gap finding.
- `docs/PRODUCTION_CHECKLIST.md` — this gap tracked there as tech debt.
- `docs/PERFORMANCE_TARGETS.md` (Part 13) — the offline-load-time target this gap currently blocks.

## 13. Critères d'acceptation

- [x] Every mutating flow (booking, review, payment, profile edit) has a documented offline
  behavior — honestly reported as "not implemented" where that's the truth, not glossed over.
- [x] Conflict policy stated per entity type (§4), grounded in real existing DB constraints where
  they already provide the guarantee (booking slots, review uniqueness) rather than assuming a
  client-side mechanism that doesn't exist.

## 14. Livrables

- `docs/OFFLINE_STRATEGY.md` (this file)
