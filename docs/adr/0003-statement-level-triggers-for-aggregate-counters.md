# ADR-0003: Statement-level triggers (not row-level) for aggregate counters

**Status**: Accepted (Enterprise Final 100 CP8, 2026-07-05).

## Context

`salons.monthly_bookings_count` was kept current by `trg_increment_monthly_bookings`, a
`FOR EACH ROW` trigger that ran one `UPDATE salons` per inserted `bookings` row. A real
400,001-row bulk-insert scale test found this caused a ~2-minute statement timeout around
150,000-300,000 rows — N sequential trigger executions (each its own row-lock acquisition on the
same `salons` row) for one INSERT statement (Master Inventory P2-22).

## Decision

Convert to a `FOR EACH STATEMENT` trigger with `REFERENCING NEW TABLE AS new_rows` — fires exactly
once per INSERT statement regardless of row count, aggregating all affected salons' row-count
deltas via one `GROUP BY`-based `UPDATE`. Live-tested (CP8): a single-row insert still credits
exactly +1 (identical behavior to before for the overwhelmingly common case); a multi-salon bulk
insert in one statement (5 rows salon A + 3 rows salon B) credited each salon exactly its own
count, with zero cross-contamination.

## Why this is the general pattern, not a one-off fix

Any trigger that maintains a per-parent aggregate (a count, a sum, a rolling total) off a
child-table INSERT should default to this shape, not `FOR EACH ROW`, unless the aggregation logic
is genuinely row-order-dependent (rare). `FOR EACH ROW` triggers on high-volume child tables are
exactly the shape that silently caps bulk-insert throughput — the cost is invisible at low volume
(a handful of rows per statement, the normal booking-creation path) and only appears once a bulk
operation (an import, a migration backfill, a scale test) hits the same table.

## Consequences

- If a future migration adds another per-parent aggregate trigger on a high-volume table
  (`bookings`, `transactions`, `activity_logs`), default to `FOR EACH STATEMENT` +
  `REFERENCING ... AS new_rows` + `GROUP BY` from the start, rather than writing `FOR EACH ROW`
  and discovering the same ceiling again later.
- The old per-row function (`increment_monthly_bookings_count`) was left in place, unreferenced,
  rather than dropped in the same migration — a separate, lower-risk cleanup can remove it once
  the statement-level version has run in production for a while.
