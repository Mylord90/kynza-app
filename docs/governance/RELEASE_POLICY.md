# KYNZA — Release Policy

**Date**: 2026-07-07 (Backend Governance Phase 3). **Defines**: versioning convention, tagging,
and what must be true before a release is cut — for the backend (Supabase migrations/Edge
Functions) and the Flutter app, which have different release surfaces and different gates.

---

## Backend releases (Supabase)

The backend has no separate "release" artifact — a migration or Edge Function deploy *is* the
release, gated exactly as `BACKEND_GOVERNANCE_GUIDE.md` §2/§4 already specify (dr-scratch test,
approval, deploy, live re-verification). This policy adds only the **tagging** convention: after
any Category B or C change closes (`CHANGE_POLICY.md`), tag the closing commit
`backend-<topic>-<date>` (e.g. `backend-p2-5-ecr-2026-07-07`) if the change is significant enough
to want a durable reference point — not mandatory for every Category A fix.

**Baseline tag**: `docs/governance/PHASE_4_REFERENCE_BASELINE.md` recommends the first such tag
for this governance closure itself.

## Flutter app releases

Existing, confirmed-real convention (per `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:395`):
`MAJOR.MINOR.PATCH+BUILD` (currently `1.0.0+1`), enforced live via `check_app_version()` RPC. This
policy formalizes when each segment increments:
- **PATCH**: bug fixes, no new user-visible capability.
- **MINOR**: new user-visible feature, backward-compatible.
- **MAJOR**: breaking change to data format, minimum-supported-version bump that locks out old
  clients, or a fundamental UX overhaul.
- **BUILD**: increments on every release build submitted to a store, regardless of the above.

## What must be true before any release is cut (backend or app)

1. `flutter analyze` → 0 issues (the floor this project has held since Enterprise Hardening's
   Phase 0 baseline — never regressed below).
2. Full test suite green, 0 failures (skips allowed only if individually justified, matching
   existing practice).
3. For a backend-affecting release: migration count and Edge Function versions re-verified live
   against production immediately before, matching `BACKEND_MAINTENANCE_GUIDE.md`'s routine checks.
4. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 reflects the true current state —
   not stale, per Phase 1's own corrected failure mode.
5. A `CHANGELOG.md` entry exists for the release (see `docs/governance/PHASE_4_REFERENCE_BASELINE.md`
   for the initial changelog this policy establishes going forward).

## Store submission releases (Play Store / App Store)

Gated additionally by the four External Go-Live Dependencies
(`docs/governance/MAINTENANCE_POLICY.md`) — a store release cannot be cut until its
platform-specific blockers (real keystore for Play Store; Apple Developer enrollment + iOS build
for App Store) are resolved by their owner. This policy does not change that gate; it only adds
the versioning/changelog discipline above once those externals clear.
