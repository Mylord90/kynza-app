# Reliability Certificate — Remediation v1

**Verdict: CONDITIONAL**, with more of its constituent parts genuinely closed than most other
domains.

## Certified unconditional

- **Disaster recovery, schema layer**: unchanged and re-confirmed valid — Certification v1/CP7's 5
  real fault-injection cycles (RPC, trigger, table, Edge Function, storage-object loss, each
  provoked/observed/restored/confirmed live on `kynza-dr-scratch`) are not affected by anything
  this pass touched. Schema RPO=0, RTO measured in minutes.
- **Application-data backup**: real, restorability-proven, for the first time ever — see
  `PHASE_0_BACKUP_CONFIRMED.md`.
- **This pass's own rollback discipline**: every one of the 18 migrations in
  `MIGRATION_APPLICATION_PLAN.md` has a specific (not generic) rollback statement; the 2 real bugs
  found in the security-fix drafts (Phase 2) were themselves caught and corrected using the same
  before/after discipline the DR runbook itself models.

## Still Conditional

- **P1-3 (residual)**: the real backup is one-time, not on a recurring schedule. No automated
  protection exists for whatever changes in production between now and whenever the next manual
  backup happens.
- **Rollback plans for the 4 security migrations and 14 feature migrations are documented, not
  live-drilled** — Phase 2 tested that the *fixes* work; it did not additionally roll each one back
  on `kynza-dr-scratch` to prove the rollback statement itself is correct. A reasonable, disclosed
  gap given time constraints, not silently assumed fine.
- **`create-backup` remains export-only** — no restore-from-backup code path exists (re-confirmed
  unchanged from every prior pass's finding). The Phase 0 backup proves data *can* be extracted and
  reloaded manually; it doesn't mean an automated restore mechanism exists.

## Evidence

`PHASE_0_BACKUP_CONFIRMED.md`, `MIGRATION_APPLICATION_PLAN.md`, `PHASE_2_SECURITY_FIXES.md`,
`docs/certification/PHASE_7_DISASTER_RECOVERY.md` (unchanged, cross-referenced not re-derived).
