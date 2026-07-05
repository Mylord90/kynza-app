# DevOps Certificate — Remediation v1

**Verdict: PARTIALLY UNCONDITIONAL.** The core CI automation claim is now genuinely true for the
first time in this project's history; release automation and secret management remain open.

## Certified unconditional

- **CI/CD genuinely executes** — 5 real runs, 3 real bugs found and fixed as a direct result of
  finally running it (missing `build_runner` step, OS-mismatched golden tests, missing Firebase-
  config handling), ending in a full green run. `flutter analyze`/`flutter test` are now
  CI-enforced on every push to `main`, not just a locally-run claim repeated across 5 prior passes.
  See `PHASE_4_READINESS_CLOSURES.md`.
- **Git history is clean** — re-confirmed by Certification v2's own secrets scan before this pass's
  push; no secret was ever committed across the 60 commits pushed this phase.

## Still open

- The `Deploy (stub)` job is exactly that — a placeholder with no real deploy target or Play Store
  service account wired. This was never in scope to build under this remediation pass (it needs a
  real deploy destination decision, not a fix).
- No release-signing secrets (`KEYSTORE_BASE64`, etc.) are wired into CI, because the real keystore
  itself doesn't exist yet (P1-4, deliberately deferred to Mylord).
- `CRON_SECRET` (the security fix for P2-3) is not yet set as a production Edge Function secret or
  Vault entry — an explicit precondition documented in `MIGRATION_APPLICATION_PLAN.md` before that
  migration can safely apply.

## Evidence

`PHASE_4_READINESS_CLOSURES.md`, `docs/certification-v2/CP6_DEVSECOPS_INFRA.md` (secrets-scan
baseline, unchanged), GitHub Actions run history (`28718162264` → `28730270227`).
