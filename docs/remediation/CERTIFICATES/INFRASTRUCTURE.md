# Infrastructure Certificate — Remediation v1

**Verdict: PARTIALLY UNCONDITIONAL.** This is the domain with the most real, immediately-verified
progress this pass — two long-standing "never done" findings are now genuinely closed with
evidence, not documentation. Two others remain open and are named explicitly.

## Certified unconditional (real, evidenced, no caveats)

- **CI/CD is genuinely provisioned and executing** — not just a file that exists. 5 real runs this
  pass, 3 real bugs found and fixed purely by giving the pipeline its first execution (missing
  `build_runner` step, OS-dependent golden tests, missing Firebase-config handling), ending in a
  full green run across all 4 jobs (Analyze & Test, Build Release APK, Manual approval gate, Deploy
  stub). Confirmed via the GitHub Actions API, run IDs in `PHASE_4_READINESS_CLOSURES.md`.
- **A real production data backup exists and is restorability-proven** — 55 tables, 156 rows,
  280KB, taken 2026-07-04, restorability proven via an actual load-and-verify cycle on
  `kynza-dr-scratch`. See `PHASE_0_BACKUP_CONFIRMED.md`. Closes the "zero backups ever taken"
  finding for real.

## Still open (named explicitly, not glossed over)

- **P1-3 (residual)**: the backup above is a one-time manual export, not a recurring schedule. No
  `pg_cron` job calls `create-backup`, and doing so for real requires a service-role-authenticated
  variant of that function (it currently requires an owner/manager JWT) — deliberately not
  built under this pass's time pressure per the "don't rush a fix" rule. Recommend as its own
  scoped follow-up.
- **P1-4**: the real Android upload keystore does not exist. Per Mylord's explicit choice this
  pass, not generated here — remains a to-do, with the exact `keytool` command and custody guidance
  in `PHASE_4_READINESS_CLOSURES.md` §1.
- The CI pipeline's `Deploy (stub)` job is, as its name says, still a placeholder — no real deploy
  target or Play Store service account is wired. Not a regression, unchanged from how the
  Hardening pass originally scoped it.

## Evidence

`PHASE_0_BACKUP_CONFIRMED.md`, `PHASE_4_READINESS_CLOSURES.md`, `MASTER_ISSUES_MATRIX.md` (P1-3,
P1-4), GitHub Actions run IDs `28718162264` → `28730270227`.
