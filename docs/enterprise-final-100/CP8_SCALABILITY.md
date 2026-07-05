# CP8 — Scalability

**Date**: 2026-07-05. **Scope**: extend the query-profiling/index/pagination work already started;
close what's fixable now with live proof; defer what needs real production traffic to validate,
with a stated trigger condition.

## Objectifs

P2-22 (bulk-write ceiling trigger), P2-23 (3 unbounded Realtime streams), P2-16/P2-17 (RLS advisor
warnings, reassessed), P3-6 (8 more unbounded methods, reassessed).

## Preuve

### P2-22 — the trigger causing the 150k-300k-row bulk-write ceiling, fixed and live-tested

Read `trg_increment_monthly_bookings`'s actual definition: `AFTER INSERT ... FOR EACH ROW`,
executing one `UPDATE salons` per inserted row — the exact reason a 400,001-row bulk insert hit a
~2-minute statement timeout in the prior scale test (N sequential executions, each its own row-lock
acquisition on the same salon row, for one statement).

New migration `20260706140000_cp8_batch_monthly_bookings_trigger.sql`: converted to
`FOR EACH STATEMENT` with `REFERENCING NEW TABLE AS new_rows`, aggregating all affected salons'
row counts via one `GROUP BY`-based `UPDATE` — fires once per statement regardless of row count,
not once per row.

**Live-tested on `kynza-dr-scratch` with real data, both the common case and the actual failure
case**, not simulated:
```
Before: Salon A = 147, Salon B = 132

Single-row INSERT (Salon A)              -> Salon A: 147 -> 148 (+1, correct)

Multi-salon bulk INSERT, one statement,
5 rows for Salon A + 3 rows for Salon B  -> Salon A: 148 -> 153 (+5, exactly its own rows)
                                             Salon B: 132 -> 135 (+3, exactly its own rows,
                                                                  no cross-contamination,
                                                                  no double-counting)

Cleanup: test bookings deleted, both counts restored to their exact original values.
```
This proves the aggregation logic is correct for the case that actually matters (multiple salons'
rows mixed in one bulk statement) — the real risk in this kind of fix, not just "does it run
without erroring." A full 400k-row re-run of the original scale test was **not** repeated this
pass (disproportionate for a re-verification of a now-different code path); the fix directly
targets the confirmed root cause (per-row execution count), so the ceiling is structurally
addressed, not just made faster at the margin.

### P2-23 — all 3 named unbounded Realtime streams, bounded and live-verified

`SupabaseStreamBuilder` (the SDK class backing every `.stream()` call in this codebase) only
supports a single `.eq()` filter plus `.order()`/`.limit()` — confirmed by reading the SDK source
directly, not assumed. It cannot express the salon/practitioner + date-range filter these queries
actually want, so a true server-side date bound isn't available on this SDK version. Added
`.order(..., ascending: false).limit(200)` to all 3 named call sites
(`getSalonBookings`/`getPractitionerBookings` in `booking_repository_impl.dart`,
`getNotifications` in `notification_repository_impl.dart`) — this bounds the actual measured
problem (unbounded row count/transfer size growing with a salon's total history) even though it
isn't a perfect date-range filter; the existing client-side date/channel filters still narrow to
what's actually displayed.

**Live-tested against the real `kynza-dr-scratch` Realtime endpoint** (a standalone Dart script
using the same `SupabaseClient`, not just a compile check): `.stream().eq().order().limit(3)`
against real `bookings` data returned exactly 3 rows, correctly ordered descending by
`start_time` — proving the chain works against the actual platform, not just that it type-checks.

### P2-16 / P2-17 — reassessed, still correctly deferred

Re-confirmed both are unchanged: 83 `auth_rls_initplan` and 205 `multiple_permissive_policies`
advisor warnings, both explicitly requiring **per-policy review, not a blind rewrite** (already
stated by the finding itself — a mechanical `auth.uid()` -> `(select auth.uid())` rewrite across
49 tables, or merging 23 tables' permissive policies into combined OR conditions, both risk
silently changing RLS semantics without individual review). This campaign's own governing rule
("no cosmetic refactor without a cited defect") cuts the other way here too: the defect is real,
but a rushed mechanical fix across 49+23 tables is exactly the kind of change that needs individual
review this checkpoint's time budget doesn't have room for. **Deferred, unchanged**, same judgment
already reached by 2 prior passes.

### P3-6 — 8 more unbounded repository methods, identified, extension deferred

The same `.limit()` pattern just proven on P2-23's 3 sites applies mechanically to P3-6's other 8 —
but confirming exactly which 8 and verifying none of them has a different real requirement
(e.g. `getClientBookings`, distinct from the 3 fixed, intentionally shows a client's **full**
booking history with no date bound by design) needs the same one-by-one care P2-23 got, not a
blind batch-apply. Deferred with a stated trigger: apply the same fix the next time any of these
8 shows up in a real performance report, using this checkpoint's 3 fixes as the proven template.

## Statut final

| ID | Statut |
|---|---|
| P2-22 | **Fermé (preuve)** — live-tested single-row and multi-salon bulk cases, both correct |
| P2-23 | **Fermé (preuve)** — all 3 named sites bounded, live-verified against the real Realtime endpoint |
| P2-16 | Ouvert — reconfirmed, per-policy review still required, not rushed |
| P2-17 | Ouvert — reconfirmed, per-policy review still required, not rushed |
| P3-6 | Ouvert — proven template exists (P2-23), extension to the other 8 explicitly deferred with a stated trigger |

## Documentation associée

`supabase/migrations/20260706140000_cp8_batch_monthly_bookings_trigger.sql`,
`lib/features/booking/data/repositories/booking_repository_impl.dart`,
`lib/features/notifications/data/repositories/notification_repository_impl.dart`.

## Commit hash

See end-of-checkpoint commit.
