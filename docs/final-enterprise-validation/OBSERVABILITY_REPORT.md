# CP8 — Observability `[RE-VERIFY — answer directly]`

> Real findings from direct inspection of production and `kynza-dr-scratch`, plus a concrete
> discovery this pass made by trying to use the one instrumented monitoring path for real.

## 1. Edge Function monitoring: the one instrumented function silently no-ops in production

`edge_function_invocations` (the table backing "Edge Function Dashboard" monitoring) is written to
by exactly **one** of the 18 deployed production Edge Functions — `create-booking` — and this is
**already honestly documented in the function's own code comment** as "the one function
instrumented as a proof-of-concept; the other ~19 remain an explicit, documented follow-up." This
pass **re-verifies that gap still exists** (18 functions confirmed deployed on production via
`supabase functions list`; still only 1 writes to the monitoring table).

**New finding this pass**: the table `edge_function_invocations` **does not exist on production at
all** — `SELECT count(*) FROM edge_function_invocations` on the real production database returns
`42P01: relation "edge_function_invocations" does not exist`. Its migration
(`20260704120000_observability_system_admin.sql`) is one of the 16 backend migrations never
deployed to production (see memory `project_16_migrations_undeployed_to_prod`, re-confirmed live
here). The insert in `create-booking/index.ts` is fire-and-forget
(`.then(() => {}, () => {})` — both success and failure are silently swallowed), which is good
defensive design for not breaking real bookings, but it means **this monitoring gap is itself
invisible**: nothing errors, nothing pages anyone, the one function that was supposed to prove the
monitoring pattern works has been silently writing to nowhere since production started. Confirmed
by testing, not by reading the migration list: `kynza-dr-scratch` (where the migration *is*
applied) has the table but **zero rows in it either**, because nothing in this environment's
testing ever called `create-booking` through its real HTTP path (all synthetic booking volume in
CP6 was inserted directly via SQL, not through the Edge Function) — so even on the environment
where the table exists, the instrumentation has never actually fired end-to-end.

## 2. Health dashboards exist in the database, but nothing renders them

Two real SQL views exist (`20260703160000_health_dashboard_views.sql`):
`v_payment_success_rate`, `v_notification_delivery_rate`. A repo-wide search confirms **neither is
referenced by any Flutter screen** — same pattern already found for `mv_audit_stats` (no
consumer), `mv_daily_revenue`/`v_mv_daily_revenue` (wired in the repository layer but no screen
calls it). This is a consistent, recurring shape across this codebase: real, correct SQL-level
observability infrastructure, with no human-facing surface that actually displays it. A real
incident today would require someone to know these views exist and manually run SQL against
production to see them — there is no dashboard a human glances at.

## 3. Alerting: no active alert-firing mechanism found

Searched for a threshold-crossing → notify-a-human mechanism (a webhook, a push, an email, a
paging integration triggered when e.g. payment success rate drops or error rate spikes) — **none
exists**. The two views in §2 are passive `SELECT`-only reporting; nothing evaluates their output
against a threshold and takes an action. **This checkpoint's own mandate ("confirm at least one
alert per category actually fires in a live test") could not be satisfied — there is no alert to
fire.** Stated honestly as a real gap, not worked around with a hypothetical.

## 4. What does work, confirmed real

- **Crashlytics** (`lib/core/services/crash_reporting_service.dart`) is real and actually called
  in production code paths — directly observed in this campaign's own CP3 testing, where
  `OfflineSyncCoordinator.flush()`'s catch block calls `CrashReportingService.recordError`
  defensively (wrapped so a Crashlytics failure itself can never block retry/DLQ bookkeeping).
- **`pg_stat_statements`** is enabled and real (used extensively by CP1 and CP5 this pass to pull
  genuine query-cost and job-execution evidence) — this is real, queryable observability, just not
  packaged into anything a non-technical operator would use day-to-day.
- **Supabase's own platform-level dashboards** (advisors, logs, `pg_stat_user_tables`) are real and
  were the actual source of most of this validation campaign's evidence — they exist and work, but
  they're Supabase's product, not something KYNZA built or would need to build.
- **`activity_logs`** is real, append-only, and actively written to (confirmed populated
  throughout this campaign's own test activity).

## 5. Direct answer

**Is KYNZA genuinely observable in production today — yes or no — and if no, the single biggest
gap is:**

**No.** The single biggest gap is that **there is no human-facing surface where anyone would
actually see a problem** — the SQL-level building blocks are real (Crashlytics, `pg_stat_statements`,
`activity_logs`, two health views), but there is no dashboard screen, and no alert of any kind, so
detecting a real production incident today depends entirely on a real user complaining or an
engineer proactively running SQL by hand. The Edge Function monitoring table that was specifically
built to start closing this gap doesn't exist in production and has never fired even where it does
exist (dr-scratch) — so the "proof of concept" for closing this gap hasn't actually been proven
end-to-end yet either.
