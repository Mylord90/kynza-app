# KYNZA — Final Remediation Report (Remediation v1)

> Closing report for the 6-phase remediation pass. Tag: to be applied as `remediation-v1` after
> this commit. Every claim below cites the phase report or certificate it comes from — nothing here
> is re-asserted without a source.

## 1. What is genuinely done

Pure code/doc changes with zero production-data footprint — these are **APPLIED**, not drafted,
and already live in this repo (several also now running in CI, which is itself newly real):

- **A real production data backup, taken and restorability-proven.** 55 tables, 156 rows, 280KB,
  git-ignored. Restorability proven via an actual load-and-verify cycle on `kynza-dr-scratch`
  (3 tables, 16 rows, zero mismatches). See `PHASE_0_BACKUP_CONFIRMED.md`.
- **One deduplicated Master Issues Matrix**, replacing 5 overlapping/sometimes-contradictory prior
  reports — 49 distinct issues (1 P0, 8 P1, 21 P2, 19 P3), each with corroboration count, evidence,
  repro steps, proposed fix, and status. See `MASTER_ISSUES_MATRIX.md`.
- **A dependency-verified, 0-BLOCKER migration application plan** for all 18 unapplied migrations,
  with a specific (not generic) rollback plan per migration. See `MIGRATION_APPLICATION_PLAN.md`.
- **Targeted regression tests for every code path this pass's own security fixes touched** — 6 new
  live tests, all passing against `kynza-dr-scratch`, CI-relevant, zero production footprint.
- **CI/CD genuinely provisioned and executing for the first time in this project's history.** 5
  real runs, 3 real bugs found and fixed purely by finally running the pipeline (missing
  `build_runner` step, OS-dependent golden tests, missing Firebase-config handling), ending in a
  full green run across all 4 jobs. See `PHASE_4_READINESS_CLOSURES.md`.
- **The keystore contradiction between two prior passes resolved with direct evidence** (both
  passes were right about different things — the build wiring is real, the real keystore file
  isn't).
- **12 domain certificates**, each either unconditional-with-evidence or explicitly conditional
  naming its exact blockers — no certificate overclaims. See `CERTIFICATES/`.

## 2. What is fixed-but-blocked (the largest bucket — and that's honest, not a failure)

Everything below has a **tested** fix (not just a draft, and not just a description) sitting in
this repo, proven against `kynza-dr-scratch` with real before/after evidence, and is
**DRAFTED, AWAITING APPROVAL** per Rule 8 — none of it is applied to production:

| Item | Matrix ID | Fix location | Tested how |
|---|---|---|---|
| `staff_profiles.invitation_token` public exposure (P0) | P0-1 | `20260704190000...sql` (+ 2 Flutter files) | Live exploit before (3,003 tokens exposed) / after (blocked) on dr-scratch |
| `staff_profiles.salon_id` mass-assignment | P1-1 | `20260704200000...sql` | Live exploit before/after |
| `create_default_document_templates` unauthenticated write | P2-1 | `20260704210000...sql` | Live exploit before/after |
| `get_staff_week_rank` loose anon grant | P3-15 | Bundled in `20260704210000...sql` | `has_function_privilege` before/after |
| `calculate-commission` cross-tenant disclosure | P2-2 | Edge Function code (already committed) | Live exploit before/after + legit-path sanity check |
| `run-scheduled-actions`/`schedule-reminders` cron-secret bypass | P2-3 | Edge Function code + `20260704220000...sql` | Live exploit before/after, full `pg_cron`-command execution proof |
| 14 backend feature migrations (CMS, remote config, feature flags, legal center, catalog, A/B testing, business observability, audit business, Health Center, perf indexes) | P1-2 | See `MIGRATION_APPLICATION_PLAN.md` | Validated on `kynza-dr-scratch` by the Backend Completion pass; dependency-order re-verified this pass |

**Every one of these is a decision away from being live**, not a discovery away.

## 3. What is still fully open, and why

| Item | Matrix ID | Why it's still open |
|---|---|---|
| Real Android upload keystore | P1-4 | Explicitly Mylord's action per this pass's own choice (irreversible, one-way secret) |
| Recurring automated backup | P1-3 (residual) | Needs a service-role-authenticated backup variant — a real, scoped follow-up, not invented under this pass's time pressure |
| Privacy Policy / Terms real content | P1-6 | Legal/business content, not a code task |
| iOS platform work | P1-7 | A full second-platform launch effort, explicitly out of scope for a remediation pass |
| Play Store Data Safety form | P1-8 | A Play Console task (the verified data inventory to fill it correctly already exists) |
| Bank transfer real details | P2-19 | Business data, not a code fix |
| `is_system_admin` grant/audit mechanism | P2-8 | Newly flagged this pass; appropriately scoped to land with or after P1-2's migration |
| Remote Config admin gate still `role==='owner'` | P2-9 | Trivial fix, oddly never applied across 4 checkpoints of the original pass — flagged again |
| 2 `SECURITY DEFINER` views bypass RLS | P2-4 | Needs re-derivation of which is an intentional trade-off before a fix can be written safely |
| `auth_rls_initplan` / `multiple_permissive_policies` perf warnings | P2-16, P2-17 | Deliberately not mechanically rewritten — needs per-policy review, not a blind find-replace |
| Missing `updated_at` triggers (3 tables) | P2-18 | Simple, never fixed across 4 passes — good next-session candidate |
| `proxipay_sessions` duplicate-session gap | P2-11 | Most-repeated (5x) never-fixed finding in the whole matrix — also a good next-session candidate |
| Repository-layer bypass / datasource pattern debt | P3-2, P3-3 | Refactor-scale, correctly deferred by 3 prior passes |
| `core`↔`feature` circular dependencies | P3-1 | Refactor-scale, first found this remediation cycle (Certification v2) |
| Zero repository-layer test coverage (23.29% overall) | P2-10 | Needs new mocking infrastructure, correctly deferred by 2 prior passes |
| MANAGER/SYSTEM_ADMIN role isolation untested | P2-6 | Coverage gap, not a known failure |

## 4. What Mylord needs to decide (not do — decide)

In the order that unblocks the most:

1. **Approve the security migration batch** (`20260704190000`, `200000`, `210000`, `220000`) and 2
   Edge Function deploys (`calculate-commission`, cron-secret versions of `run-scheduled-actions`/
   `schedule-reminders`) — closes P0-1, P1-1, P2-1, P2-2, P2-3. **Before approving #4 specifically**,
   confirm the `CRON_SECRET` precondition will be set in production (function secret + Vault entry)
   — `MIGRATION_APPLICATION_PLAN.md` Group 1.
2. **Approve the 14-migration feature batch**, in the documented timestamp order — closes P1-2 and
   makes CMS/remote config/feature flags/legal center/catalog/A-B testing/business observability/
   audit business/Health Center genuinely live.
3. **Decide the recurring-backup approach**: a `pg_cron`-callable variant of `create-backup`, or a
   manual calendar-reminder SOP.
4. **Decide whether/when to generate the real Android upload keystore** — a one-way, irreversible
   action; needs a durable custody plan (who stores the `.jks` and passwords long-term) before it's
   generated, not after.
5. **Provide real Privacy Policy/Terms content, real bank transfer details** — both are pure
   content/business decisions with an already-built delivery mechanism waiting for them.
6. **Decide iOS's place in the roadmap** — is it in scope for a near-term launch, or a deliberately
   later, separate initiative?
7. **A smaller, quick decision**: approve applying the trivial fixes for P2-9 (Remote Config admin
   gate), P2-11 (`proxipay_sessions` duplicate constraint), and P2-18 (3 missing `updated_at`
   triggers) — none are security-critical, all are simple, all have been flagged and never fixed
   across multiple passes now.

## 5. Is it safe to begin UI/UX Premium in parallel?

**Yes — directly, unambiguously.** UI/UX Premium work is Flutter-side design/screen/widget work
with no schema or Edge Function footprint of its own; nothing in items #1-#7 above blocks it, and
none of this pass's fixes touched shared UI infrastructure in a way that would conflict with
parallel frontend work.

**One nuance, stated plainly so it isn't missed**: if UI/UX Premium work includes screens that
specifically consume one of the 14 still-undeployed features (CMS content, remote config values,
A/B test variants, feature-flag-gated behavior), those screens can be fully built and tested
against `kynza-dr-scratch` right now — but won't show real production data or affect real users
until Mylord approves and this pass's Phase 3 plan applies that migration batch. That's a sequencing
detail for those specific screens, not a blocker for starting UI/UX Premium as a workstream.

## 6. What this pass did not do, honestly

- Did not apply any migration, RLS policy, or Edge Function deployment to production — by design,
  per Rule 8, zero exceptions.
- Did not re-test Performance or client-device metrics — no Android/iOS device/emulator available
  in this environment, unchanged limitation across every pass to date.
- Did not resolve the 2 `SECURITY DEFINER` view findings (P2-4) — needs re-derivation before a safe
  fix can be written, not force-fit into this pass's time budget.
- Did not build repository-layer test coverage or resolve the 2 architecture-debt findings (P3-1,
  P3-2, P3-3) — all three explicitly refactor-scale, correctly deferred rather than rushed.
- Did not generate the real Android upload keystore or write real legal/business content — both
  are explicitly Mylord's decisions, not code tasks.

## Tag

`remediation-v1`, applied after this report is committed.
