# CP0 — Concurrency Architecture: AtomicClaimService

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

Every claim below is backed by a real test run in this session (Dart unit tests, or a live
concurrent-request script against `kynza-dr-scratch`) — see "Evidence" under each fix. No result
is invented or estimated.

## 0. Why this checkpoint exists

The Final Enterprise Validation pass (2026-07-05, `docs/final-enterprise-validation/`) live-
reproduced two concurrency bugs sharing one root cause: **a list of "pending" items was read and
processed without first atomically claiming it**, so two concurrent triggers could both read the
same snapshot and both act on it before either recorded that it had:

1. `OfflineSyncCoordinator.flush()` — two concurrent flushes both read `outbox.pending()` before
   either called `outbox.remove()`, double-applying every item.
2. `run-scheduled-actions` — two concurrent cron invocations both selected the same
   `automation_action_runs` row (`WHERE status='pending'`), double-processing it. Live-reproduced:
   a real duplicate row landed in `activity_logs`; since 4,012/5,015 seeded actions are
   `send_notification`, this would double-send a real WhatsApp/push in production.

CP0 builds one reusable claim architecture and retrofits it onto both bugs, then audits the rest
of the codebase for the same missing-claim shape.

## 1. Audit — every "process pending items" location

Before designing the fix, every location in the codebase reading a "pending"/"due"/"queued" list
and then looping over it was audited (Edge Functions, pg_cron jobs, Hive-backed client queues).
Full method in the audit; results:

| Location | Had an atomic claim already? | Action |
|---|---|---|
| `OfflineSyncCoordinator.flush()` | No | **Fixed** (§2) |
| `LegalAcceptanceService.flushQueue()` | No — same shape, previously undiscovered | **Fixed** (§2) |
| `run-scheduled-actions` | No | **Fixed** (§3) |
| `schedule-reminders` | Weak (TOCTOU `notification_logs` pre-check, no DB backstop) | **Fixed** (§4) |
| `OfflineSyncCoordinator`'s `data_deletion_request` branch | Idempotency check present but no DB unique constraint backstop (unlike `reviews.booking_id`) | **Fixed** (§5) |
| `claim-referral`, `validate-qr` | Yes — conditional `UPDATE ... WHERE status='pending' ... RETURNING` | No change needed |
| `calculate-commission` | Yes — `INSERT` guarded by `UNIQUE(booking_id)`, `23505` treated as already-done | No change needed |
| `mark-no-show`, `rollback-remote-config`, `update-remote-config`, `create-backup` | N/A — single-row operations, not a select-many-then-loop | No change needed |
| `execute-workflow` | N/A — only inserts new rows it then owns exclusively; never reads pre-existing pending rows | No change needed |
| pg_cron jobs (`reset-monthly-bookings-count`, `release-expired-bookings`, `refresh-mv-daily-revenue`, `kynza-refresh-audit-stats`) | N/A — direct atomic `UPDATE`/`REFRESH`, no read-then-loop | No change needed |

**Root-cause enabler found**: `KynzaOfflineBanner` (`lib/shared/widgets/kynza_offline_banner.dart`)
is embedded independently in ~40 different screens, each keeping its own `State` that calls
`OfflineSyncCoordinator.flush()` **and** `LegalAcceptanceService.flushQueue()` independently on the
same connectivity flip. Because Flutter keeps previous-route `State` objects alive in the
navigator stack, two or more mounted instances (e.g. screen A pushes screen B, both showing the
banner) fire concurrently on one reconnect — this makes both bugs **concretely reachable in normal
app usage**, not just a theoretical race requiring a contrived test harness. This is why the fix
had to live inside the flush methods themselves (serializing regardless of caller count), not in
the banner widget (fixing ~40 call sites individually would be fragile and easy to regress).

## 2. Client-side fix — `AtomicClaimService` (`lib/core/services/atomic_claim_service.dart`)

A reusable mutual-exclusion guard: `runExclusive(key, body)` ensures only one `body` runs per
`key` at a time; a second caller under the same key awaits the first call's result instead of
starting a duplicate run. `OfflineSyncCoordinator.flush()` and `LegalAcceptanceService.flushQueue()`
both wrap their existing loop in `runExclusive` under a fixed (not per-instance) key, so it
serializes regardless of how many `KynzaOfflineBanner` instances are mounted. Also exposes
`backoffWithJitter(attempt)` — exponential backoff with jitter, capped — as a documented, tested
utility for any future periodic/scheduled consumer (not wired into these two flows: they're
reconnect-event-triggered, already naturally rate-limited by real connectivity changes, and their
existing tests assert "flush N times = N attempts" semantics that timer-based backoff would break).

**A real implementation bug was caught and fixed during this work**: the first version of
`runExclusive` chained `body().whenComplete(...)` and stored/returned the wrapped future — this
compiled and looked correct but caused the awaited future to never resolve even after the body had
fully finished running (reproduced with a minimal standalone test, `await
AtomicClaimService.instance.runExclusive('k', () async { print('x'); })` hung for the full 30s test
timeout). Rewritten as a plain `async`/`try`/`finally` guard, which resolved it — proof is that
every test below now passes where it previously hung.

### Evidence

- `test/unit/offline_fault_injection_test.dart` — the "Concurrent flush() race" test (previously
  `skip:`'d with the bug documented) is **un-skipped and passes**: two concurrent `flush()` calls
  across 5 queued items now apply each item exactly once.
- `test/unit/legal_acceptance_service_test.dart` — new test: two concurrent `flushQueue()` calls
  across 5 queued items apply each item exactly once (this bug was previously undiscovered — found
  by this pass's audit, not carried over from the prior campaign).
- `test/unit/atomic_claim_service_test.dart` — new, direct unit tests for `AtomicClaimService`
  itself: coalescing behavior, independent keys, re-run after completion, exception propagation
  releases the lock, and `backoffWithJitter`'s growth/cap/jitter properties.
- The "Phone restart during an active outbox flush" test (pre-existing, models a real process
  kill) required one addition: `AtomicClaimService.instance.reset()` at the "restart" point,
  documented inline as modeling reality — a real process kill wipes all in-memory state including
  the lock map; only the Hive-backed queue data survives to disk. Without this the test would
  incorrectly model an in-memory lock surviving a process death.
- Full suite: `flutter analyze` → 0 issues; `flutter test` → 394 passed, 5 skipped (pre-existing,
  unrelated), 0 failed.

## 3. Server-side fix — `run-scheduled-actions` atomic claim RPC

`claim_pending_action_runs(p_batch_size, p_stale_after_minutes, p_max_attempts)` — a `plpgsql`
function using `SELECT ... FOR UPDATE SKIP LOCKED` inside an `UPDATE ... RETURNING`, so the row
lock acquisition and the claim (`status='pending' → 'processing'`, `claimed_at=NOW()`) happen in
one atomic statement. Two concurrent callers can never both receive the same row: Postgres skips
any row already locked by the other transaction. A stale claim (a prior claimer crashed before
finalizing) is reclaimable after `p_stale_after_minutes` (default 10, comfortably above the
function's real execution time). `run-scheduled-actions/index.ts` now calls this RPC instead of a
plain `SELECT ... WHERE status='pending'`; `recordActionRunResult`'s backoff-reschedule branch now
explicitly resets `status` back to `'pending'` (previously implicit/unset) so a claimed-then-
rescheduled row becomes reclaimable again at its new `scheduled_at`.

Draft migration: `supabase/migrations/20260705100000_cp0_concurrency_atomic_claims.sql` (adds
`'processing'` to the status check constraint, adds `claimed_at`, creates the RPC). **Not applied
to production** per Rule 8 — applied only to `kynza-dr-scratch` to run the live test below.

### Evidence (live, on `kynza-dr-scratch`, not production)

Seeded one real pending `automation_action_runs` row (`send_notification` type, real FK-valid
`salon_id`/`action_id`/`execution_log_id`), then fired two concurrent HTTP calls to
`claim_pending_action_runs` via the PostgREST RPC endpoint:

```
Call A claimed our row: 1 time(s)
Call B claimed our row: 0 time(s)
PASS: exactly one of the two concurrent calls claimed the row.
Row state after claim race: [{"status":"processing","claimed_at":"2026-07-05T07:58:32...","attempt_count":0}]
```

This is the same shape of live test that originally reproduced the bug (a real duplicate
`activity_logs` row) — this time proving the opposite result under the fix.

## 4. Server-side fix — `schedule-reminders` atomic claim

`schedule-reminders` previously checked `notification_logs` for an existing row before invoking
`send-notification` — a genuine TOCTOU race if two hourly runs ever overlapped (a run taking >1h).
`notification_logs` itself can't carry a uniqueness backstop (one event legitimately produces
multiple rows: push, whatsapp, in_app channels). New table `reminder_dispatch_claims (booking_id,
event_type)` with a composite primary key backs this scheduler's own idempotency instead: the loop
now inserts a claim row first — a `23505` conflict means another run already claimed it and this
run skips it; only the winning insert proceeds to call `send-notification`. Same "insert wins the
claim" idiom already used by `claim-referral` and `calculate-commission` elsewhere in this
codebase.

### Evidence (live, on `kynza-dr-scratch`)

```
Insert A status: 201 null
Insert B status: 409 {"code":"23505", ..., "message":"duplicate key value violates unique constraint \"reminder_dispatch_claims_pkey\""}
PASS: exactly one insert succeeded, the other hit the unique-constraint conflict.
```

## 5. Defense-in-depth — `data_deletion_requests` unique backstop

`OfflineSyncCoordinator`'s `data_deletion_request` branch already has an idempotency pre-check
(query for an existing pending request), but — unlike `reviews.booking_id` (`UNIQUE`) — the table
had no DB-level backstop, so a second write path (a future admin tool, or a bug in a future client
version) could still double-insert. Added a partial unique index:
`(user_id) WHERE status='pending' AND deleted_at IS NULL`.

### Evidence (live, on `kynza-dr-scratch`)

```
Insert A status: 409 {"code":"23505", ..., "message":"duplicate key value violates unique constraint \"idx_data_deletion_requests_one_pending_per_user\""}
Insert B status: 201 null
PASS: unique partial index backstop rejects the second concurrent pending request.
```

## 6. Migration guide for future modules

Any new "process pending items" module (future automation types, batch jobs, sync queues) must
pick the matching pattern:

- **Server-side (Postgres/Edge Function)**: claim rows via `UPDATE ... SET status='processing' ...
  WHERE id IN (SELECT id FROM ... WHERE status='pending' ... FOR UPDATE SKIP LOCKED) RETURNING *`
  — either inline (single-row, like `claim-referral`) or via a batch RPC (like
  `claim_pending_action_runs`) for a cron-driven batch runner. Never `SELECT` a batch and process
  it in a loop without this claim step first.
- **Client-side (Hive/local queue)**: wrap the flush loop in
  `AtomicClaimService.instance.runExclusive(fixedKey, body)` using a key that is NOT per-instance
  (any UI trigger point may be mounted more than once). Do not rely on the UI trigger being
  single-instance.
- **Idempotency key**: every queue item needs one (`MutationOutboxService` already has a UUID
  `id`; `LegalAcceptanceQueueService` uses the natural composite `(userId, documentVersionId)`).
- **Retry budget + DLQ**: cap attempts, route exhausted items to a dead-letter store — both
  existing Dart queues and `automation_action_runs` already do this; keep the pattern for new ones.

## 7. Exit criteria

- [x] `OfflineSyncCoordinator` double-flush — closed, live-tested (Dart concurrency test, un-skipped).
- [x] `run-scheduled-actions` double-processing — closed, live-tested on `kynza-dr-scratch`.
- [x] Every other "process pending items" location audited — 2 additional real gaps found
  (`LegalAcceptanceService`, `schedule-reminders`) and fixed; 1 defense-in-depth gap
  (`data_deletion_requests`) closed; all other locations confirmed already safe.
- [x] `flutter analyze`: 0 issues. `flutter test`: 394 passed / 5 skipped (pre-existing) / 0 failed.
- [x] No migration or Edge Function deployed to production — draft migration only, verified on
  `kynza-dr-scratch`, CLI re-linked back to the production ref (read-only) at the end of this
  checkpoint.
