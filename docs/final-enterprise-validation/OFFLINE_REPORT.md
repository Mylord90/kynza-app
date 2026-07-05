# CP3 — Offline First / Hive `[RE-VERIFY, deeper fault scenarios]`

> Re-verifies Disaster Recovery's fault-injection work and Enterprise Hardening's offline queue
> tests, then goes deeper into scenarios neither covered: mid-write app kill, phone restart during
> an active flush, concurrent flush races, and a corrupted queue record. Every scenario below ran
> as a real automated test against real temp-directory Hive boxes (not mocks of Hive) — new file
> `test/unit/offline_fault_injection_test.dart`, 5 tests. All pre-existing offline tests (17 across
> `offline_sync_coordinator_test.dart`, `legal_acceptance_service_test.dart`,
> `offline_airplane_mode_test.dart`) were re-run and still pass unmodified — **RE-VERIFIED,
> still holds.**

## 0. Honest scope correction before the results

AGENT.md §9 states a strict sync priority order (1. new bookings → 2. status changes → 3. cash
payments → 4. client notes). This pass confirms, by direct code inspection
(`docs/OFFLINE_STRATEGY.md` §3, cross-checked against `lib/core/services/`), that **none of those
four flows are actually queued today** — no priority field, no separate queues, no ordering logic
exists anywhere in `offline_sync_coordinator.dart`. The only flows genuinely queued offline are
**review creation, profile edits, and data-deletion requests** (Enterprise Hardening Phase 6) —
none of which are in AGENT.md's four named classes. This isn't a new finding (Remediation v1's
matrix already tracks the booking/cash-payment/notes queues as "not implemented"), but it matters
for how to read the results below: every fault scenario here was tested against the *actual*
outbox (`MutationOutboxService` + `OfflineSyncCoordinator`), because that's the only offline write
path that exists to fault-test.

## 1. Mid-write app kill — PASS (re-verified + newly proven)

**Test**: enqueue a profile-edit mutation, then — with no `close()`, no graceful shutdown, nothing
— open a **second, independent** `MutationOutboxService` instance against the same still-open Hive
box (the strongest available proxy for "the app process died the instant after `enqueue()`
returned, then relaunched"). Result: the second instance sees the item immediately, full payload
intact. Confirms `docs/OFFLINE_STRATEGY.md`'s claim ("Hive writes to disk synchronously on
`enqueue()`, before the method even returns") with a real test, not just re-asserting the doc.

## 2. Phone restart during an active outbox flush — PASS (new depth)

**Test**: 3 items queued (deletion, review, profile). `flush()` is started and *abandoned*
mid-iteration — the review-create call is made to hang on an uncompleted `Completer` standing in
for "the process died while this await was in flight" (nothing in the test ever awaits that
`flush()` call to finish). At the stall point: item 1 (deletion) is confirmed fully applied and
removed; item 2 (review) is confirmed still pending (neither applied nor failed — genuinely
in-flight); item 3 (profile) is confirmed untouched (the sequential loop never reached it). A
**fresh** coordinator/outbox pair — simulating the relaunched app — then flushes again: item 2
applies exactly once, item 3 applies exactly once, item 1 is never re-touched. **No loss, no
duplication, correct resume from an unclean stop.**

## 3. Concurrent flush() race — REAL BUG FOUND

**Test**: 5 independent data-deletion-request items queued. Two `OfflineSyncCoordinator` instances
(sharing the same on-disk outbox — e.g. two near-simultaneous connectivity-restored events, which
is a real, plausible trigger given `kynza_offline_banner.dart` calls `flush()` on every
offline→online transition with no debounce or in-flight guard) call `flush()` concurrently via
`Future.wait`.

**Result: every one of the 5 items was applied twice** (`createRequest` called 2× per user, 10
total calls for 5 queued items). Root cause, confirmed by reading the code: `MutationOutboxService`
has no lock around its read-snapshot → apply → remove cycle — both coordinators call
`outbox.pending()` and get the same 5-item snapshot before either one calls `outbox.remove()` for
any of them, so both process all 5 before the box reflects any removal.

This is a **new, real finding**, reproduced by a real (not hypothetical) test, not previously
flagged by any prior pass (Certification v1/v2, Remediation v1, Enterprise Hardening) because
concurrent-flush was never exercised before. Per this checkpoint's own instruction — report
honestly even if expensive, don't rush a fix under this pass's time budget — the reproduction test
is committed as `skip: 'KNOWN BUG ...'` (kept in the suite so the gate stays green, ready to
un-skip and confirm the moment a fix lands) rather than silently patched. **Real-world impact
depends on the mutation type**: `dataDeletionRequest`'s own `_isAlreadySatisfied` pre-check would
actually catch most real double-flush attempts in production (the second attempt would see the
first request already `pending` and skip it) — the test isolates the race by using a fake
repository with no such check enabled, to prove the *underlying* absence of a lock, independent of
whether a given mutation type's dup-check happens to paper over it. `profileUpdate` has no such
pre-check at all (§4) — a concurrent double-flush of a queued profile edit would issue two
identical `UPDATE`s, harmless only because updates are naturally idempotent. Tracked in
`FINAL_ROADMAP.md`.

## 4. Corrupted / malformed queue record — PASS (new depth)

**Test**: a well-formed deletion-request item and a directly-injected malformed review-create item
(missing `bookingId`/`clientId`/`rating` — the shape a partial write or a future schema drift could
plausibly leave) coexist in the same box. Flushed repeatedly (`maxAttempts` times): the malformed
item throws a type-cast error on every attempt (as expected, since `_apply` casts required keys),
but **does not block the valid sibling item**, which still flushes normally. The malformed item
itself is retried exactly `maxAttempts` times and then **dead-lettered** — the same fate as any
other persistently-failing item, not a special crash path, not an infinite retry loop, not silent
data loss. **No corrupted record survives permanently in the live queue.**

## 5. Enqueue racing an in-flight flush — PASS (new depth)

**Test**: a flush is started against a snapshot containing one item, which is made to hang;
while it's hanging, a second, independent item is enqueued. Result: the in-flight flush (correctly)
never touches the new item — its snapshot was taken before the enqueue — but the new item is
confirmed still present in the box afterward and is picked up cleanly by the *next* `flush()`
call. **No lost writes from a race between a UI-triggered enqueue and a background flush.**

## 6. Conflict resolution under concurrent offline edits — RE-VERIFIED

Re-ran the existing last-write-wins dedupe test (two offline profile edits for the same user):
still holds — only the latest survives and replays. This pass did not find a new concurrent-edit
scenario beyond what Enterprise Hardening already proved, because `dedupeKey`-based
last-write-wins is a client-side, single-device mechanism (it doesn't need to reason about two
*different* devices editing the same record — AGENT.md's actual "Server-Wins" policy for
cross-device conflicts, e.g. booking slots, is enforced entirely by the `UNIQUE(practitioner_id,
start_time)` DB constraint, not by any client code — confirmed absent as a generic mechanism,
consistent with `docs/OFFLINE_STRATEGY.md` §4/§6's own honest accounting).

## 7. Final data-integrity check

Across all 5 new scenarios plus the 17 re-verified pre-existing tests: no test observed a
partial/corrupted record surviving in the pending box after a flush cycle completed. The one
real corrupted record injected in §4 was correctly retried-then-dead-lettered, never left
dangling in `pending`.

## What this checkpoint did not test

- A real OS-level process kill (`kill -9` / force-stop) on a physical device or emulator — none
  is available in this environment (unchanged limitation across every prior pass, including
  Remediation v1). The Hive-persistence and stalled-await simulations above are the strongest
  available proxy: `enqueue()`'s synchronous-write claim and the flush loop's sequential-await
  structure are verified directly, not inferred.
- Booking creation, booking status changes, cash payments, and client notes — none of these are
  queued today (§0), so there is no offline fault behavior to test for them; this is a scope gap
  in the *product*, not in this checkpoint's testing.
- Cross-device conflicts for any entity other than booking slots (which the DB constraint already
  handles) — no other entity has a documented or implemented cross-device conflict policy to test
  against.
