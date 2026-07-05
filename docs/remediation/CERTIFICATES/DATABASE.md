# Database Certificate — Remediation v1

**Verdict: CONDITIONAL.** The schema and migrations themselves are sound (0 BLOCKER across all 18
in scope), but a large share of the schema that's supposed to exist in production doesn't yet, and
several real RLS/security-adjacent findings remain open.

## What's real

- All 18 unapplied migrations reconciled and dependency-verified this pass (not assumed from prior
  narrative) — `MIGRATION_APPLICATION_PLAN.md`. 0 BLOCKER.
- The 2 real bugs found in the security-fix drafts this pass were both database-level
  (`security_invoker` view semantics, `REVOKE ... FROM anon` vs `PUBLIC` grant semantics) — genuine,
  non-trivial Postgres/Supabase knowledge applied, not just documentation.
- A real, restorability-proven backup of every production table now exists (`PHASE_0_BACKUP_CONFIRMED.md`).

## Still Conditional

- **P1-2**: 14 migrations (including all FK-index and catalog/legal-center/CMS/etc. work) absent
  from production.
- **P2-4**: 2 `SECURITY DEFINER` views (`v_popular_searches`, `v_mv_daily_revenue`) bypass caller
  RLS — flagged by the Postgres advisor, routed for review, no fix drafted yet (deliberately, since
  one of the two may be an intentional trade-off that needs re-derivation before writing a fix).
- **P2-16 / P2-17**: 83 `auth_rls_initplan` warnings across 49 tables, 205 `multiple_permissive_policies`
  warnings across 23 tables — performance anti-patterns, not correctness bugs, deliberately not
  mechanically rewritten (risk of silently changing policy semantics without individual review).
- **P2-18**: 3 tables (`salon_settings`, `permission_groups`, `automation_workflows`) have an
  `updated_at` column with no trigger to maintain it — "a real correctness bug, not a design
  choice" per the Documentation Architecture pass, never fixed across 4 subsequent passes.
- **P2-11**: `proxipay_sessions` has no unique constraint preventing concurrent duplicate sessions
  per booking — the single most-repeated never-fixed finding in the entire matrix (5 independent
  passes flagged it).

## Evidence

`MASTER_ISSUES_MATRIX.md` (P1-2, P2-4, P2-11, P2-16, P2-17, P2-18), `MIGRATION_APPLICATION_PLAN.md`,
`PHASE_0_BACKUP_CONFIRMED.md`.
