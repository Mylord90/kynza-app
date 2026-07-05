# Observability / Monitoring Certificate — Remediation v1

**Verdict: CONDITIONAL.** Same root cause as Backend Completion and Database: the observability
*code* is real, but almost none of it is live in production.

## What's real

- All 7 Health Center dashboard RPCs, the `edge_function_invocations` table, and the
  `has_system_admin()` scope gating them exist and were validated against `kynza-dr-scratch` by the
  Backend Completion pass. Classified SAFE, ready to apply
  (`MIGRATION_APPLICATION_PLAN.md`, migration #8).
- CI now provides real, continuous observability into the codebase's own health for the first
  time — every push is analyzed and tested automatically (`PHASE_4_READINESS_CLOSURES.md`).

## Still Conditional

- **P1-2**: none of the 7 Health Center dashboards exist in production today — confirmed via a
  direct `information_schema`/`pg_proc` check this pass (re-confirming Certification v2/CP5's
  original discovery, not just citing it).
- **P2-20**: zero alerting/threshold code exists anywhere in the codebase — `grep -rn
  "alert|threshold|Alert"` project-wide, still 0 matches, unchanged since Certification v1/CP4.
  Meaningless to build alerting on dashboards that don't exist in production yet (P1-2).
- **P2-7**: several Edge Functions (confirmed: `accept-invitation`, and spot-checked
  `calculate-commission`/`claim-referral`) don't populate `ip_address`/`device_info` on their
  `activity_logs` writes despite the columns existing — an audit-quality gap that made this
  session's own Gate 0-style exploitation checks weaker than the schema implies they should be.

## Evidence

`MASTER_ISSUES_MATRIX.md` (P1-2, P2-7, P2-20), `MIGRATION_APPLICATION_PLAN.md`,
`PHASE_4_READINESS_CLOSURES.md`.
