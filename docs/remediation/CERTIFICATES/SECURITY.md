# Security Certificate — Remediation v1

**Verdict: CONDITIONAL.** Cannot be certified unconditional while a confirmed P0
(account-takeover vector) sits unpatched in production.

## What changed this pass (real, evidenced)

- All 5 security findings carried over from Certification v1/v2 (P0-1, P1-1, P2-1, P2-2, P2-3 in
  `MASTER_ISSUES_MATRIX.md`) now have **fixes that are drafted, applied to `kynza-dr-scratch`, and
  proven with real before/after exploit evidence** — see `PHASE_2_SECURITY_FIXES.md`. This is a
  step beyond every prior pass, which only ever drafted or (for the vulnerabilities themselves)
  exploited — never both applied *and* re-exploited the fix.
- 2 of those 5 drafted fixes contained real bugs that would have shipped broken had they been
  applied as-is; both found and corrected by actually testing rather than reviewing
  (`PHASE_2_SECURITY_FIXES.md` §1, §4).
- Regression coverage added and CI-enforced: `test/live/remediation_v1_security_fixes_test.dart`
  (6 tests) plus the pre-existing 7 live tests, all passing against `kynza-dr-scratch`.

## Why this is still Conditional, not certified

- **P0-1** (`staff_profiles.invitation_token` public exposure) — fix drafted, tested, **not applied
  to production**. Production remains exactly as exploitable as when Certification v1/CP6 first
  found it.
- **P1-1** (`staff_profiles.salon_id` mass-assignment) — same status.
- **P2-1** (`create_default_document_templates` unauthenticated write) — same status.
- **P2-2** (`calculate-commission` cross-tenant financial disclosure) — same status.
- **P2-3** (`run-scheduled-actions`/`schedule-reminders` cron-secret bypass) — same status, plus an
  explicit unmet precondition in production (`CRON_SECRET` must be set as both an Edge Function
  secret and a Vault entry before this fix can safely apply — see
  `MIGRATION_APPLICATION_PLAN.md` Group 1, item 4).
- Also open, not addressed this pass (out of the 5-finding scope the remediation prompt named):
  **P2-4** (2 `SECURITY DEFINER` views bypass caller RLS), **P2-5** (oversized-payload DoS-shaped
  finding, 0/20 Edge Functions have a body-size limit), **P2-6** (MANAGER/SYSTEM_ADMIN role
  isolation never independently live-tested), **P2-21** (certificate pinning inert, no root/
  jailbreak detection).

## What would make this unconditional

Mylord's explicit approval to apply the 4 security migrations (`20260704190000`, `20260704200000`,
`20260704210000`, `20260704220000`) and deploy the 2 patched Edge Functions
(`calculate-commission`, and the cron-secret-checking versions of `run-scheduled-actions`/
`schedule-reminders`) to production, per the exact order and preconditions in
`MIGRATION_APPLICATION_PLAN.md` Group 1.

## Evidence

`MASTER_ISSUES_MATRIX.md` (P0-1, P1-1, P2-1 through P2-6, P2-21), `PHASE_2_SECURITY_FIXES.md`,
`MIGRATION_APPLICATION_PLAN.md`.
