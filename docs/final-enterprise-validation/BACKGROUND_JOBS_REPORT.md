# CP5 — Background Jobs `[NEW DEPTH / RE-VERIFY idempotency]`

> Real idempotency/concurrency tests against `kynza-dr-scratch`'s actual `pg_cron` jobs and
> deployed Edge Functions — live HTTP invocations with real before/after row counts, not code
> review alone. One genuine, previously-undiscovered concurrency bug was reproduced with a live
> race, and a second was found by direct schema inspection (absence of a constraint that would
> have caught it). Both are reported honestly per this checkpoint's own rule, not silently patched.

## 1. Real inventory of scheduled jobs (`cron.job`, `kynza-dr-scratch`)

| job | schedule | mechanism |
|---|---|---|
| `release-expired-bookings` | every minute | direct SQL `UPDATE` |
| `kynza-refresh-audit-stats` | hourly | `SELECT refresh_audit_stats()` |
| `refresh-mv-daily-revenue` | nightly (00:00) | `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
| `kynza-booking-reminders` | hourly | HTTP → `schedule-reminders` Edge Function (cron-secret gated) |
| `kynza-run-scheduled-actions` | every 5 min | HTTP → `run-scheduled-actions` Edge Function (cron-secret gated) |
| `reset-monthly-bookings-count` | monthly (1st, 00:00) | direct SQL `UPDATE` |

Both Edge Functions were confirmed `ACTIVE` and deployed on `kynza-dr-scratch`
(`supabase functions list`). Both were invoked live over real HTTP with the real cron-secret
header this checkpoint used from `vault.decrypted_secrets` — the same gate Remediation v1's P2-3
fix put in place, confirmed still enforced (a request without the header is rejected before any
of the tests below ran).

## 2. `release-expired-bookings` — idempotent by construction, RE-VERIFIED

Ran the exact cron SQL twice, back-to-back, directly: `UPDATE bookings SET status='cancelled', ...
WHERE status='pending_payment' AND created_at < NOW() - INTERVAL '5 minutes'`. Second run
necessarily matches zero rows (the first already flipped their status out of `pending_payment`),
so **no duplicate side effect is possible even under a true concurrent race** — Postgres's own
row-level locking serializes two simultaneous executions, and whichever loses just matches nothing.
This is the same job CP1 found had run 2,543 times for real via `pg_stat_statements` with no
errors — re-confirms that finding, now with an explicit double-run proof of its idempotency
mechanism, not just an absence-of-errors inference.

## 3. `run-scheduled-actions` — REAL BUG FOUND: concurrent invocations double-process the same row

**Test**: inserted one real `pending` `automation_action_runs` row (action type `log_activity` —
chosen because its side effect, a row in `activity_logs`, is trivial to count precisely) directly
into `kynza-dr-scratch`, satisfying real FK constraints (`automation_actions`,
`automation_execution_logs`). Fired **two genuinely concurrent** HTTP invocations of
`run-scheduled-actions` (backgrounded shell processes hitting the real deployed function at the
same instant, not sequential calls).

**Result**: both invocations returned `{"status":"processed","count":1}` — **both picked up and
processed the same single row.** Real, measured consequence: **exactly 2 rows** landed in
`activity_logs` for that one queued action (12ms apart), not 1.

**Root cause** (confirmed by reading `supabase/functions/run-scheduled-actions/index.ts`): the
function does `SELECT ... WHERE status='pending' LIMIT 50` and then loops calling `processRun()`
on each row — there is no atomic claim step (`UPDATE ... SET status='processing' WHERE
status='pending' RETURNING`, `FOR UPDATE SKIP LOCKED`, or any advisory lock) between reading the
"pending" snapshot and acting on it. Two overlapping invocations (a real, plausible trigger: the
cron fires every 5 minutes with no overlap guard, so a slow previous run still executing when the
next tick fires would race exactly like this test did) will both see the same rows as pending and
both execute them.

**Real-world blast radius**: 4,012 of the 5,015 real `automation_actions` seeded on this project
are `send_notification` — meaning in production, this exact race would send a **duplicate
WhatsApp/push notification** to a real client, staff member, or owner, not just write an extra
audit-log row. `stampLoyalty`/`addLoyaltyBonus` (1,003 seeded actions) would be similarly
double-applied.

**This is the same architectural shape as the bug CP3 found in `OfflineSyncCoordinator`**
(read-snapshot-then-act with no lock) — appearing independently in a completely different
subsystem. That's worth flagging as a pattern, not just two unrelated bugs: this codebase has now
shown the same "list pending → iterate → act" idiom twice, in two unrelated queue-processing
services, without a claim/lock step either time. Per this checkpoint's mandate, this is logged as
a tracked finding, not patched under this pass's time budget — see `FINAL_ROADMAP.md`. Test data
(the probe row, its action/execution-log, and the 2 duplicate `activity_logs` rows) was cleaned up
after confirming the result; nothing from this reproduction was left in `kynza-dr-scratch`.

## 4. `schedule-reminders` — same category of bug, found by code + schema inspection (not re-run live)

Reading `supabase/functions/schedule-reminders/index.ts`: for each due booking, it does `SELECT
... FROM notification_logs WHERE related_booking_id=X AND event_type=Y ... maybeSingle()` and,
only if nothing is found, calls `send-notification`. This is a **check-then-act** pattern with no
atomicity between the check and the send — the same category of race as §3, just via a
read-then-write idiom instead of a claim-then-process one. Confirmed there is **no database-level
backstop**: `notification_logs` has no unique constraint on `(related_booking_id, event_type)` —
only its primary key — so nothing would even reject a duplicate insert if the race fires. Not
re-reproduced live in this checkpoint (§3 already proved the underlying category of bug once,
live, with real evidence; re-running the identical shape of race against a second function would
cost real time for a result whose root cause is already established), but the finding is real,
schema-confirmed, and actionable: **no unique constraint exists to catch this even as a
last-resort safety net.** Tracked in `FINAL_ROADMAP.md` alongside §3.

## 5. `create-backup` — same TOCTOU shape, lower real-world risk

`create-backup`'s 6-hour rate limit (`BACKUP_COOLDOWN_SECONDS`) is also a check-then-act
(`SELECT recent backups in the last 6h` → proceed if none). Same category, but meaningfully lower
risk in practice: it's Owner-triggered manually (not cron-driven), so a real double-trigger
requires the Owner to invoke it twice within milliseconds of each other, and the consequence (one
extra backup snapshot) is far less harmful than a duplicate customer-facing notification or a
double-applied loyalty stamp. Noted for completeness, not separately reproduced.

## 6. Materialized view refreshes — idempotent by nature

`refresh_audit_stats()` and `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue` are pure
recomputation — running either twice, concurrently or not, converges to the same correct state
(worst case, Postgres itself serializes or errors on a genuinely simultaneous `REFRESH
CONCURRENTLY` on the same MV, which is a database-level protection, not an application concern).
No live re-test needed beyond CP1's already-real `pg_stat_statements` timings for these two jobs.

## 7. Execution order / timeout / rollback

- No explicit ordering dependency exists between the 6 jobs (none reads output another produced
  within the same run), so there is no cross-job ordering guarantee to test.
- Timeout handling: `run-scheduled-actions` caps its batch at 50 rows per invocation
  (`BATCH_SIZE`), bounding worst-case single-invocation duration; no explicit Edge Function
  timeout override was found configured beyond the platform default.
- Rollback on partial failure: `run-scheduled-actions`' per-row `try` shape (via
  `recordActionRunResult`'s failed-attempt/backoff path, re-verified still functioning per
  Remediation v1) means a failure partway through a 50-row batch leaves already-processed rows
  correctly marked and unprocessed rows correctly still `pending` for the next tick — this part of
  the design is sound; the gap found in this checkpoint is specifically the missing claim step
  before that per-row logic runs, not the per-row logic itself.

## 8. What this checkpoint did not test

- Did not live-reproduce the `schedule-reminders` race (§4) — the underlying bug category was
  already proven live in §3; re-spending the same live-reproduction effort on a second function
  with an identical root cause wasn't judged worth the additional time in this pass.
- Did not test `create-backup`'s race live (§5) — manually-triggered, low real-world likelihood,
  low-harm consequence.
- Did not test behavior under an Edge Function cold-start/timeout mid-execution — no mechanism in
  this environment to reliably force that condition against a live deployed function.
