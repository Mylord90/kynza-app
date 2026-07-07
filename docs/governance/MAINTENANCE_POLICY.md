# KYNZA — Maintenance Policy

**Date**: 2026-07-07 (Backend Governance Phase 3). **Defines**: when the backend is in
maintenance mode, what that means, and the one condition that ends it.

---

## What maintenance mode means

The backend has no known internal engineering debt at P0/P1 severity (per
`docs/governance/FINAL_GOVERNANCE_REPORT.md`'s evidence). It is not being actively developed —
it is being **kept correct**: security patches if a new finding surfaces, bug fixes if a real
defect is reported, dependency/platform updates as needed, and nothing else, until either a new
business requirement or a newly-discovered issue changes that.

## Entry condition

Maintenance mode begins when `docs/governance/FINAL_GOVERNANCE_REPORT.md` is published stating
zero P0/P1 internal engineering debt remains open (external dependencies excluded, per
`docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §5.2's severity table) — this document takes effect
at that point.

## What is permitted during maintenance mode

Per `docs/governance/CHANGE_POLICY.md`'s categories:
- **Category A (small, targeted) changes**: bug fixes, security patches, dependency bumps,
  documentation corrections — no campaign required, standard commit + PR discipline
  (`docs/governance/CONTRIBUTION_POLICY.md`).
- **Category B (targeted session) changes**: a single-topic RCA/ECR/verification pass, exactly
  like the P2-5 RCA/ECR or this governance effort — scoped, time-boxed, closes with its own
  report, updates the canonical Master Inventory per `BACKEND_GOVERNANCE_GUIDE.md` §1.2.

## What is forbidden without ending maintenance mode first

- **Category C (campaign-scale) work**: a new multi-checkpoint audit, hardening pass, or feature
  build spanning multiple subsystems. Starting one is a deliberate decision (see
  `CHANGE_POLICY.md` §3 for the exact trigger), not something that happens incidentally during
  maintenance.
- Any new business feature, new Edge Function, new migration that isn't a direct fix for a
  reported defect.

## Exit condition

Maintenance mode ends the moment a Category C campaign is deliberately started (a new audit,
a new feature initiative, a platform migration) — not automatically, and not silently. Whoever
starts that campaign states explicitly that maintenance mode is paused for its duration, and
`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` gains a dated note recording the pause,
matching this project's existing convention of dated update sections rather than silent
divergence — precisely the failure `docs/governance/PHASE_1_DOCUMENTARY_UNIFICATION.md`
corrected once already.

## The four items maintenance mode does not wait on

Per `docs/governance/FINAL_GOVERNANCE_REPORT.md`: the Android upload keystore, real legal
content, iOS platform work, and the Play Store Data Safety form are External Go-Live Dependencies,
not engineering debt. Their resolution does not require ending maintenance mode or starting a new
campaign — they are Mylord/business actions tracked in
`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 exactly as they are today, resolved
whenever their owner acts, independent of this policy.
