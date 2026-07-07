# KYNZA — Contribution Policy

**Date**: 2026-07-07 (Backend Governance Phase 3). **Applies to**: any contributor — human or AI
agent (Claude Code or otherwise) — making a change to this repository.

---

## Before writing any code

1. Check `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 — is this already tracked?
2. Classify the work per `docs/governance/CHANGE_POLICY.md` (Category A/B/C).
3. Read the relevant standing reference doc for the area touched
   (`docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §6.1's canonical-per-topic table; for
   Flutter/UI work, the corresponding guide under `docs/`).
4. If Supabase is touched: no local Docker/Postgres stack exists in this project —
   `kynza-dr-scratch` is the only pre-production target, confirmed across this project's entire
   history.

## Coding standards

Not restated here — this project's existing per-domain conventions remain authoritative:
`docs/ai/skills/kynza-ai-coding-rules.md` and the domain-specific skill files under
`docs/ai/skills/` for Flutter/Supabase/security/testing patterns. This policy adds only the
process wrapper (what to do before/after writing code), not new code style rules.

## Commit conventions

Conventional-commit-style prefixes, matching this project's own history throughout: `feat(...)`,
`fix(...)`, `docs(...)`, `security(...)`, `refactor(...)` — scope in parentheses names the
campaign/session/area (e.g. `docs(governance)`, `security(p2-5-ecr)`). One clean commit per
logical unit of work; for a multi-phase Category B/C session, one commit per phase/checkpoint,
each with its own closure evidence in the commit message — the pattern this entire project has
used since its first campaign.

## Review requirement

- **Category A**: no formal review gate beyond the approval already required for anything
  production-bound (`BACKEND_GOVERNANCE_GUIDE.md` §2.4/§4).
- **Category B/C**: the same production-approval gate, plus — since these sessions are typically
  checkpoint-gated — the explicit "STOP and wait for approval before the next checkpoint" pattern
  this project has used throughout (P2-5 RCA, P2-5 ECR, this governance effort itself), unless the
  governing instructions for that specific session explicitly say otherwise.

## Evidence discipline (the one rule that overrides all others)

**No claim of "fixed," "closed," "done," or "verified" without the direct evidence that proves it**
— a live query result, a real exploit re-attempt, an actual test run's output, a real command's
output. This project's entire multi-campaign history is built on this discipline; every governance
document in this folder exists specifically to keep it from eroding as more sessions accumulate.
Restating an unverified claim from a prior report as if newly confirmed is exactly the failure
this governance effort's Phase 1 found and corrected — don't reproduce it.

## Handling a discovered documentary or process inconsistency

Per `docs/governance/BACKEND_MAINTENANCE_GUIDE.md`'s own section on this: verify with direct
evidence, propose the exact correction explicitly, apply only after that's clear — never silently
rewrite a document, regardless of how obviously wrong it looks.
