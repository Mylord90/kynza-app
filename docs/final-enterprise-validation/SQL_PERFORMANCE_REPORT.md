# CP1 — SQL Performance `[CLOSE THE GAP]`

> Extends Certification v1 Phase 2 (Database Optimization) and Remediation v1's P2-16/P2-17
> findings. Every number below is a real measurement taken via `supabase db advisors` /
> `supabase db query` (EXPLAIN ANALYZE / pg_stat_statements / pg_stat_user_tables), not an estimate.
> Two databases were used deliberately: **production** (`hhdkjfpgaklhrhfoxlhj`, read-only queries
> only — no write, no schema change) for advisor/lint findings and real usage counters, and
> **kynza-dr-scratch** (`hzjmyeptytvjmzbnsmwp`, the reusable seeded staging project) for
> `EXPLAIN ANALYZE` at representative data volume — production currently holds almost no real
> data (see §1), so a plan measured there would be trivial and misleading.

## 1. Honest baseline: production has near-zero data today

`pg_stat_user_tables` on production, ordered by row count, top 15:

| table | live rows | seq_scan | idx_scan | seq_scan % | last analyze |
|---|---|---|---|---|---|
| permission_definitions | 23 | 4 | 32 | 11% | never |
| activity_logs | 9 | 142 | 0 | **100%** | never |
| users | 7 | 486 | 270 | 64% | 2026-06-25 |
| notification_logs | 6 | 43 | 0 | **100%** | never |
| mv_audit_stats | 6 | 260 | 0 | **100%** | never |
| bookings | 5 | 8,692 | 8,907 | 49% | never |
| staff_profiles | 2 | 117 | 20 | 85% | never |
| salons | 2 | 82 | 120 | 41% | never |

Every table on production tops out in the single/double digits (consistent with Remediation v1's
backup finding of 156 rows across 55 tables). `last_analyze`/`last_vacuum` are `NEVER` on nearly
every table because autovacuum's dead-tuple threshold has never been crossed — expected at this
volume, not a bug, but it means **planner statistics have never been refreshed since table
creation**, which matters once real bookings start arriving in bulk.

**Consequence for this checkpoint**: query *plans* measured against production today would all be
trivial (sub-millisecond, single-page scans) regardless of index quality — that would be a
worthless measurement dressed up as a real one. Every `EXPLAIN ANALYZE` below was therefore run
against `kynza-dr-scratch`, which is already seeded at a representative volume (10,001 bookings,
9,014 users, 5,003 services, 5,015 automation_actions, 5,004 entity_versions — real counts, not
targets) with fresh `ANALYZE`/`VACUUM` (confirmed timestamps 2026-07-04, one day before this
measurement). Production-only findings (advisors, real usage counters) are reported separately in
§2 since they don't depend on data volume.

## 2. Real production advisor findings (`supabase db advisors --linked`, read-only)

326 total findings: 38 SECURITY (2 ERROR, 36 WARN — see `SECURITY_REPORT.md` for CP7 handling of
these), **288 PERFORMANCE** (all WARN). Breakdown by rule:

| rule | count | distinct tables | RE-VERIFY status |
|---|---|---|---|
| `multiple_permissive_policies` | 205 | 23 | **[RE-VERIFY: still open]** — matches Remediation v1 P2-17, now table-quantified |
| `auth_rls_initplan` | 83 | 49 | **[RE-VERIFY: still open]** — matches Remediation v1 P2-16, now table-quantified |

Worst offenders for `multiple_permissive_policies` (multiple RLS policies evaluated per
role×action, e.g. `owner_manager_manage_exceptions` + `staff_own_exceptions_manage` both firing on
every `anon`/`authenticated` SELECT/INSERT/UPDATE/DELETE): `availability_exceptions`,
`staff_breaks`, `staff_working_hours` — 24 findings each (6 actions × role combinations). Next
tier: `bookings`, `reviews`, `staff_profiles` — 12 each.

Worst offenders for `auth_rls_initplan` (an `auth.uid()`/`auth.jwt()` call inside a policy that
Postgres re-evaluates per-row instead of once per query): `staff_profiles`, `bookings`, `reviews`,
`automation_workflows/conditions/actions` — 4 each.

**This pass's judgment, consistent with Remediation v1's own caution**: these are real,
reproducible findings — not re-asserted from memory, freshly re-pulled this session — but fixing
them is a **per-policy rewrite** (wrap `auth.uid()` in `(select auth.uid())`, merge redundant
permissive policies into one `USING (cond1 OR cond2)`), not a mechanical find-replace, and not
something to rush under this pass's time budget. Confirmed still open, still correctly deferred as
its own scoped follow-up (see `FINAL_ROADMAP.md`).

At today's row counts (≤23 rows/table) this costs nothing measurable. The real exposure is
forward-looking: `auth_rls_initplan` cost is `O(rows scanned)`, so it compounds directly with
whatever row growth CP6 finds — this is the mechanism connecting CP1 to CP6's bottleneck list.

## 3. EXPLAIN ANALYZE — the 5 hottest screen queries, at real 10k-row volume

Query shapes reconstructed from the actual Dart call sites (file:line cited), then run as raw SQL
via `EXPLAIN (ANALYZE, BUFFERS)` against `kynza-dr-scratch`.

| # | Screen | Query (from code) | Plan | Execution time |
|---|---|---|---|---|
| 1 | Owner Calendar range (`booking_repository_impl.dart:98-125`, `getBookingsInRange`) | `bookings WHERE salon_id=$1 AND start_time BETWEEN ... AND deleted_at IS NULL` | Index Scan on `idx_bookings_salon_date` | **2.17 ms** |
| 2 | Owner/Staff Calendar **Realtime `.stream()`** (`booking_repository_impl.dart:144-190`) | `bookings WHERE practitioner_id=$1` (no date range, no `deleted_at` — filtered client-side in Dart after fetch) | Index Scan on `idx_bookings_practitioner` | **1.39 ms** today, but returns **every booking the practitioner has ever had**, not a bounded window — see §4 |
| 3 | Staff "Today" (`home_staff_screen.dart:29-35`) | `bookings JOIN users JOIN services WHERE practitioner_id=$1 AND start_time BETWEEN today AND deleted_at IS NULL ORDER BY start_time` | Index Scan `uq_practitioner_slot` + 2 index lookups | **0.23 ms** |
| 4 | Notifications **Realtime `.stream()`** (`notification_repository_impl.dart:16-31`) | `notification_logs WHERE user_id=$1` (channel/is_read/deleted_at/order/limit all applied client-side) | Index Scan on `idx_notif_logs_user` | **0.09 ms** |
| 5 | Public search RPC `search_salon_data('beaut', NULL, NULL, 30)` (`search_repository_impl.dart:43-51`, FTS migration `20260630100000`) | `websearch_to_tsquery` against GIN `search_vector` | GIN index scan | **15.05 ms** — the slowest of the five, and the only one doing real text ranking work |
| 6 | Owner Dashboard "Clients" tab (`home_owner_screen.dart:278-281`) | `bookings JOIN users WHERE salon_id=$1 AND deleted_at IS NULL` (no date filter, no `LIMIT`, aggregated client-side) | Bitmap Heap Scan `idx_bookings_salon_date` | **7.32 ms** |

**Verdict: all 5 targeted screens are index-covered today.** Every migration listed in AGENT.md
§21 / the `20260703120000_indexes_optimization.sql` and booking-schema migrations is doing its
job — no missing index was found for any of the 5 hottest patterns. This is a genuine
**re-verification pass** of Certification v1 Phase 2: still holds, now measured at 10k-row scale
instead of asserted.

## 4. New finding this pass: unbounded Realtime `.stream()` queries

Supabase's Dart Realtime `.stream()` API only supports `.eq()` — it cannot express a date range,
`deleted_at IS NULL`, or `LIMIT` server-side. Three call sites confirmed doing this (booking
calendar ×2 — salon and practitioner variants — and notifications list): the **entire** row set
matching a single equality filter is fetched over the wire every time the stream (re)connects, and
all further filtering/sorting/limiting happens in Dart. At today's volumes this is invisible
(sub-2ms, a handful of rows). It is **not** invisible once a single practitioner accumulates
thousands of historical bookings, or a user accumulates thousands of notifications — cost grows
linearly with total lifetime rows, not with what's actually displayed. Not a bug against any
functional requirement today; flagged here as a forward-looking architecture debt item because
CP6 (scalability) and CP4 (Realtime) both need to know this shape exists before interpreting their
own results. No migration needed to fix it (it's a query-construction issue in the repository
layer, not a schema/index gap) — tracked in `FINAL_ROADMAP.md` P7.

## 5. Real recurring-job cost, found via `pg_stat_statements` (ties to CP5)

`pg_stat_statements` is enabled on `kynza-dr-scratch`. Real top-cost entries (seeding-script rows
excluded from the summary below since they're one-time setup, not app traffic):

| query | calls | mean time | note |
|---|---|---|---|
| `UPDATE bookings SET status=$1, cancellation_reason=$2 WHERE status=$3 AND created_at < NOW() - INTERVAL $4` | 2,543 | 1.55 ms | the pending-booking auto-expiry job — real, recurring, cheap at this scale |
| `SELECT refresh_audit_stats()` | 43 | 99.7 ms | `mv_audit_stats` hourly refresh (AGENT.md §6) — real cost, not estimated |
| `insert into cron.job_run_details(...)` | 3,140 | 0.75 ms | pg_cron's own bookkeeping overhead — expected |
| `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue` | 2 | 214.96 ms | nightly revenue snapshot refresh |
| `net.http_post(... vault.decrypted_secrets ...)` | 136 | 13.34 ms | Edge Function webhook dispatch from a DB trigger/cron job |

These numbers directly seed CP5 (Background Jobs) — this pass measured the auto-expiry job and
both materialized-view refreshes running for real, not asserted from code review.

## 6. Locks, N+1, join order

- No lock contention observed or expected at current traffic (dr-scratch's 2,543 auto-expiry
  updates ran without any logged wait; production's real concurrent traffic is effectively zero
  per §1).
- No N+1 pattern found in the 5 audited screens — queries 3 and 6 use explicit JOINs, not
  per-row follow-up queries. This is a targeted check of the 5 named screens, not an exhaustive
  repository-layer audit (that would be new scope beyond this checkpoint).
- Join order in all EXPLAIN outputs matched the smaller/indexed side driving the join (bookings →
  users/services via PK), which is what the planner should choose and did.

## 7. Optimization list (real gain, not estimated where measured; explicitly estimated where not)

| # | Item | Type | Gain | Status |
|---|---|---|---|---|
| 1 | Consolidate `multiple_permissive_policies` (205 findings, 23 tables) | RLS policy rewrite, not index | Not directly measurable at today's ~0-row scale; scales with row count per CP6 | Deferred by design (needs per-policy review) — tracked P7 |
| 2 | Wrap `auth.uid()`/`auth.jwt()` in `(select ...)` for `auth_rls_initplan` (83 findings, 49 tables) | RLS policy rewrite, not index | Same as above | Deferred by design — tracked P7 |
| 3 | Bound the 3 Realtime `.stream()` queries (§4) | Application/repository code, not schema | Prevents unbounded linear growth in payload size; no current cost | New finding this pass — tracked P7 |
| 4 | Refresh planner stats (`ANALYZE`) once real production data starts arriving in volume | Operational, not schema | Prevents stale-stats bad plans once autovacuum's dead-tuple threshold is finally crossed | Not urgent at ≤23 rows/table; add to launch checklist |

**No new index or materialized-view migration is proposed by this checkpoint** — the 5 hottest
query patterns are already fully covered by existing indexes (§3), and items 1-2 are RLS-policy
changes explicitly out of scope for a blind schema migration per Remediation v1's own finding.

## 8. What this checkpoint did not test

- Full slow-query log across *all* screens, not just the 5 named ones — a full repository-layer
  audit is out of this checkpoint's scope (see AGENT.md tech-debt: 23.29% repo-layer test
  coverage, P2-10).
- Lock contention under real concurrent multi-user write load — no concurrent-write load generator
  was run in this checkpoint; that is CP6's job specifically, using the volumes reached there.
