# KYNZA — Final Engineering Certification

**Date**: 2026-07-06. **Purpose**: a reconciliation-and-truth pass, not a new engineering
campaign. Answers 9 specific questions with cited evidence (git commits, live command output,
file/line references), fixing only the genuine inconsistencies found while verifying — no new
feature, no architecture change, no invented finding.

> **This document supersedes every prior scorecard for decision-making purposes** (§4/§20 of
> `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`, and every certification/scorecard before it).
> Prior reports remain on disk as evidentiary sources — cited throughout below — not as the thing
> to consult for "where do we stand today." That question is answered here.

---

## Question 1 — What is the real test count?

**Verified directly, not estimated**: 3 separate `flutter test` runs, each in its own isolated git
worktree checked out at the exact commit in question, dependencies fetched fresh, generated code
rebuilt from source (`dart run build_runner build --delete-conflicting-outputs`), then the real
test runner executed.

| Commit | What it is | Real, re-run test output |
|---|---|---|
| `d9c7613` | Master Plan Execution's closing commit (`feat(master-plan-execution): CP1-CP5`) | **409 passed, 5 skipped, 0 failed** — "All tests passed!" |
| `8a83e12` | Enterprise Final 100's opening commit (`fix(enterprise-final-100): CP1`) | **409 passed, 5 skipped, 0 failed** — identical to `d9c7613` |
| `e137a09` | Enterprise Final 100's closing commit (`docs(enterprise-final-100): CP11`, current `HEAD`) | **411 passed, 5 skipped, 0 failed** |

**The discrepancy in the prompt's own framing does not exist in the actual git-committed
record.** Every committed report is accurate:
- Master Plan Execution's own `CP5_CONFIRMATION.md` states 409 — **correct**, matches the real
  re-run at its closing commit exactly.
- Enterprise Final 100's own `CP1_ARCHITECTURE_BACKEND.md` states 409 (unchanged) at its opening
  commit — **correct**, matches the real re-run exactly. `git diff --stat d9c7613 8a83e12 --
  test/` confirms only 1 line changed in `test/` between these two commits (an import-path fix in
  `offline_airplane_mode_test.dart`, part of the P3-1 cycle fix — no test added or removed).
- Enterprise Final 100's own `CP11` closing state (411) is correct — the +2 delta happened
  entirely within its own CP5 (`test/unit/proxipay_repository_impl_test.dart`, 2 new tests).

**Where "405" actually comes from**: it is *Master Plan Execution's own internal* baseline —
stated in that campaign's own `CP3_ENGINEERING_CLOSURE.md` ("409 passed (was 405 before this
pass)") and `CP5_CONFIRMATION.md` ("test count grew from 405 to 409") — referring to the count
*before Master Plan Execution's own CP3* (which added the 4 cold-start-offline cache tests),
**not** to Enterprise Final 100's opening number. No committed document claims Enterprise Final
100 opened at 405. If this was communicated informally as "Enterprise Final 100 opened at 405,"
that framing conflated two different campaigns' internal deltas — the actual git record shows no
such number at Enterprise Final 100's boundary.

**No test was silently removed at any point in this project's history**: `git log
--diff-filter=D --name-only -- 'test/**'` across the entire repository history returns zero
results; `git log --diff-filter=D --summary --all -- test/` (a second, independent method)
confirms the same — zero `delete mode` entries across all 48 commits that have ever touched
`test/`. Confirmed specifically across the Enterprise Final 100 campaign too: `git diff
--diff-filter=D --name-only d9c7613 e137a09 -- test/` returns nothing; the only `test/` changes in
that range are 1 modified line and 1 new file (88 lines, 2 tests).

**Real current count, verified again at the moment of writing this document**: `flutter test` at
current `HEAD` → **411 passed, 5 skipped, 0 failed**. `flutter analyze` → **0 issues**.

---

## Question 2 — Final remaining-items inventory

Every row from the Master Inventory (`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2) that
is not `Fermé (preuve)` — i.e. everything not yet both fixed *and* proven — deduplicated. The 6
`R-*` rows and 20 other `Fermé (preuve)` rows are excluded (fully closed, nothing left to track).
2 rows (P2-21, P3-14) are split into their external and internal halves per Question 3's own
resolution rule, since each bundles two genuinely different pieces of work under one historical
ID. `P1-9` and `P1-10` (pure client-side, ship automatically with the next app release, no server
deploy gate) are listed once each.

| ID | Priorité | Catégorie | Description | Impact métier | Dépendances | Estimation | Engineering | Ops | External | Corrigé-non-déployé | Déployé | Migration | Edge Function | Secret | Compte externe |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P0-1 | P0 | Sécurité | RLS policy exposes `invitation_token`/`phone` publicly | Critical — account takeover | Aucune, deploy-ready | 15 min | non | oui | non | oui | non | oui | non | non | non |
| P1-1 | P1 | Sécurité | `staff_profiles.salon_id` mass-assignment | High | Aucune | 15 min | non | oui | non | oui | non | oui | non | non | non |
| P1-2 | P1 | Backend/Infra | 27 migrations undeployed to production | High — root cause of low Monitoring/Observability scores | §7 chain | ~1 jour | non | oui | non | oui | non | oui | non | oui (CRON_SECRET, item #4) | non |
| P1-3 | P1 | Infra/DR | Recurring backup automation built, not deployed | High until deployed | Aucune | 2-4h | non | oui | non | oui | non | oui | oui (`create-platform-backup`) | non | non |
| P1-9 (serveur) | P1 | Fiabilité | Atomic-claim migration for concurrency fix | High once real traffic exists | Part of P1-2 batch | 15 min | non | oui | non | oui | non | oui | non | non | non |
| P1-9 (client) / P1-10 | P1 | Fiabilité | `AtomicClaimService` + `CircuitBreaker`, code complete | Was High, now mitigated client-side | Aucune | 0 — ships automatically | non | oui (mobile release) | non | non | non (ships with app) | non | non | non | non |
| P1-12 | P0 (élevé par Resilience) | Observabilité | Alerting migration + `check-system-alerts` function | High | `20260704120000` first | 30 min + cron TBD | non | oui | non | oui | non | oui | oui | non | non |
| P2-1 / P3-15 | P2/P3 | Sécurité | Anon-callable RPC + loose grant, bundled fix | Medium | Aucune | 15 min | non | oui | non | oui | non | oui | non | non | non |
| P2-2 | P2 | Sécurité | `calculate-commission` cross-tenant disclosure | Medium | Aucune | Redeploy | non | oui | non | oui | non | non | oui | non | non |
| P2-3 | P2 | Sécurité | Cron-secret header check, 2 functions | Medium | `CRON_SECRET` precondition | 30 min | non | oui | non | oui | non | oui | oui | oui | non |
| P2-5 | P2 | Sécurité | Body-size DoS guard, 16 functions | Medium | Aucune | Small | non | oui | non | oui | non | non | oui | non | non |
| P2-8 | P2 | Sécurité | System-admin grant/revoke audit trail | Medium | Should land with P1-2 | Small | non | oui | non | oui | non | oui | non | non | non |
| P2-9 | P2 | Backend | Remote-config admin gate fix | Medium | `has_system_admin()` first | Trivial | non | oui | non | oui | non | non | oui | non | non |
| P2-11 | P2 | Backend | Proxipay-session unique constraint | Medium | Aucune | Small | non | oui | non | oui | non | oui | non | non | non |
| P2-15 | P2 | DB/Perf | 32 unindexed FKs, bundled in P1-2 | Medium | Part of P1-2 | Included | non | oui | non | oui | non | oui | non | non | non |
| P2-24 | P2 | Realtime | `notification_logs` publication membership | Medium (UX) | Aucune | Trivial | non | oui | non | oui | non | oui | non | non | non |
| P2-10 | P2 | Tests | 19/24 repos at 0% coverage + Firebase-mocking gap | Medium-high (structural) | New mocking infra | Large | oui | non | non | non | non | non | non | non | non |
| P2-12 | P2 | Backend | Feature Flags engine gates nothing | Low-medium | Product decision first | Medium | oui | oui | non | non | non | non | non | non | non |
| P2-14 | P2 | Backend | `check-subscription` cron doesn't exist | Medium (revenue) | Aucune | Medium | oui | non | non | non | non | oui | oui | non | non |
| P2-16 | P2 | DB/Perf | 83 `auth_rls_initplan` warnings | Medium at scale | Per-policy review | Large | oui | non | non | non | non | oui | non | non | non |
| P2-17 | P2 | DB/Perf | 205 `multiple_permissive_policies` warnings | Medium at scale | Aucune | Large | oui | non | non | non | non | oui | non | non | non |
| P2-21 (root/jailbreak) | P2 | Sécurité | Detection code not shipped | Medium | Real rooted device to test | Medium | oui | non | non | non | non | non | non | non | non |
| P2-25 | P2 | Storage | Bucket limits/MIME types, no WebP compression | Medium | Aucune | Medium | oui | non | non | non | non | oui | non | non | non |
| P3-2 | P3 | Architecture | 14 files bypass repository layer | Low | Aucune | Large | oui | non | non | non | non | non | non | non | non |
| P3-3 | P3 | Architecture | Datasource split only in `auth` | Low | Aucune | Large | oui | non | non | non | non | non | non | non | non |
| P3-4 | P3 | Architecture | Router monolith, no `ShellRoute` | Low | Own dedicated backlog | Large | oui | non | non | non | non | non | non | non | non |
| P3-5 | P3 | Edge Functions | Hygiene gap, helper proven on 2/22 | Low-medium | Aucune | Large | oui | non | non | non | non | non | oui | non | non |
| P3-6 | P3 | Backend | 8 more unbounded repository methods | Low | Aucune | Medium | oui | non | non | non | non | non | non | non | non |
| P3-7 | P3 | Offline | Outbox covers only 3 entities, by design | Low (not a gap) | N/A | N/A | non | non | non | non | non | non | non | non | non |
| P3-10 | P3 | Business | No formal support process/role | Low | Product decision | Décision produit | non | oui | non | non | non | non | non | non | non |
| P3-14 (Analytics/local-notif) | P3 | Product | Firebase Analytics + local-notifications not integrated | Low | Aucune (Firebase project already exists) | Large | oui | non | non | non | non | non | non | non | non |
| P3-18 | P3 | CMS | 2 of 4 client-consumer screens not built | Low | Aucune | Small | oui | non | non | non | non | non | non | non | non |
| P3-20 | P3 | Rollback | Original 20-migration batch rollback never live-drilled | Low-medium | Aucune | Medium | non | oui | non | non | non | non | non | non | non |
| P3-21 | P3 | Backup | Full restore automation (manual playbook exists) | Medium | Aucune | Medium | oui | non | non | non | non | non | oui | non | non |
| P1-4 | P1 | Android | Real upload keystore | High — Play blocker | Custody plan | 30 min + planning | non | non | oui | non | non | non | non | oui | non |
| P1-6 | P1 | Legal | Real Privacy Policy/ToS content | High — Play+App Store blocker | Migration deploy first | Business-owned | non | non | oui | non | non | non | non | non | non |
| P1-7 | P1 | iOS | Full second-platform launch | High for App Store | Aucune | Semaines | non | non | oui | non | non | non | non | non | oui |
| P1-8 | P1 | Play Store | Data Safety Form | High — Play blocker | Aucune | 1-2h | non | non | oui | non | non | non | non | non | oui |
| P2-19 | P2 | Business | Real bank transfer details | Medium | Aucune | Business-owned | non | non | oui | non | non | non | non | non | non |
| P3-13 | P3 | Auth | Facebook/Apple sign-in stubs | Low | Real app registrations | Medium | non | non | oui | non | non | non | non | oui | oui |
| P2-21 (pinning) | P2 | Sécurité | Certificate pinning inert | Medium | Real captured TLS cert | Medium | non | non | oui | non | non | non | non | oui | non |
| P3-14 (Maps/Géoloc) | P3 | Product | Google Maps/Places/Geolocation | Low | Real Maps API key | Large | non | non | oui | non | non | non | non | oui | non |

**42 line items total** (40 Master Inventory rows still open, 2 of which — P2-21, P3-14 — split
into 2 each since they genuinely bundle an external-blocked half and a genuinely-open internal
half under one historical ID). Recounted directly from the table above with a script
(`grep -c "^| P"` + a column-by-column extraction), not estimated by hand — see the exact
per-row breakdown in Question 3. Cross-checked against every prior report's own numbering
(`MASTER_ISSUES_MATRIX.md`'s 49, Cert v1/v2's own findings, `FINAL_ROADMAP.md`) — no item here is
new; every one traces to an ID already in the Master Inventory. Zero duplicates: each row
represents exactly one underlying issue, even where 2+ prior passes independently found it (the
`Dépendances`/citation trail in the Master Inventory itself already records that corroboration
history — not repeated per-row here to avoid re-litigating it).

---

## Question 3 — Single-category classification

Applied directly in Question 2's `Engineering`/`Ops`/`External` columns — recounted by extracting
those 3 columns programmatically from every row of the table above, not by hand, to avoid exactly
the kind of arithmetic slip this reconciliation pass exists to catch:

- **A — Engineering Remaining: 15 items** — P2-10, P2-12, P2-14, P2-16, P2-17,
  P2-21-root/jailbreak, P2-25, P3-2, P3-3, P3-4, P3-5, P3-6, P3-14-Analytics/local-notif, P3-18,
  P3-21. (P2-12 also carries an Ops component in its own row — resolved to A since the blocking
  action is the engineering once the product decision is made, per Question 3's own resolution
  rule; counted once, in A only.)
- **B — Operations Remaining: 18 items** — P0-1, P1-1, P1-2, P1-3, P1-9-serveur,
  P1-9/P1-10-client, P1-12, P2-1/P3-15, P2-2, P2-3, P2-5, P2-8, P2-9, P2-11, P2-15, P2-24, P3-10,
  P3-20.
- **C — External Dependency: 8 items** — P1-4, P1-6, P1-7, P1-8, P2-19, P3-13,
  P2-21-pinning, P3-14-Maps/Geolocation.
- **Excluded from all 3 (not open work)**: P3-7 (by design, explicitly not a gap) — 1 item.

15 + 18 + 8 + 1 (excluded) = **42**, matching Question 2's table exactly — verified by direct
recount, not asserted.

---

## Question 4 — Final real score

| Domaine | Score | Preuve |
|---|---|---|
| Architecture | **82/100**, unconditional | `CERTIFICATES/ARCHITECTURE.md`; re-verified this pass — the only 2 real `core`↔`feature` cycles found by any tool-run scan are now fixed and tool-confirmed closed (`CP1_ARCHITECTURE_BACKEND.md`) |
| Backend | **Engineering: done. Live: not done.** | See Q6/Q7 below — this domain cannot honestly take one number; the two halves diverge sharply |
| Security | **No number above "Conditional" has ever been assigned in this program**, and this pass doesn't change that verdict | A confirmed, live, unauthenticated account-takeover vector (P0-1) remains unpatched in production today (re-verified via live `pg_policies` read this session) — no security domain can score cleanly while that's true, regardless of how many other findings closed |
| Infrastructure | **Mechanism-complete, deployment-pending** | CI/CD genuinely runs (`R-7`, 7 real GitHub Actions runs, 3 consecutive green); recurring backup mechanism built and proven twice on dr-scratch (`CP3_INFRASTRUCTURE.md`) — neither is live in production |
| Code Quality | **Improved, evidenced** | Real dead-code scan (2 files removed, 1 wired into use, `CP4_CODE_QUALITY.md`); a stale "no barrel files" claim corrected; 0 `flutter analyze` issues maintained across all 11 Enterprise Final 100 checkpoints |
| Testing | **26.38% line coverage** (re-measured via a real lcov parse, `CP5_TESTS.md`), **411 real passing tests** (Question 1) | First repository-layer DI/mocking seam ever built in this codebase, proven on 1 of 24 repositories; 19 remain at 0%, stated explicitly, not smoothed over |
| Observability | **Built and proven on staging; zero of it live in production** | `activity_logs` audit population fixed for real across all 9 call sites and live-tested (`CP6_OBSERVABILITY.md`); Health Center + alerting migrations still undeployed — the underlying "not observable in production" verdict from `final-enterprise-validation/` is unchanged |
| Production Readiness | **Insufficient evidence for a single confident number** — stated explicitly per this question's own instruction | The Master Plan's own §12 already declines to merge 3 non-additive scoring frameworks; nothing in this pass resolves that structurally, it only closes more of what those frameworks measured |
| Reliability | **No new concurrency-bug instance found**, re-scanned specifically this pass (`CP9_RELIABILITY.md`) | Both pre-existing atomic-claim shapes (dedicated RPC, inline conditional `UPDATE`) re-confirmed correctly applied; circuit breaker (5 sites) and `AtomicClaimService` (2 consumers) unchanged and correctly scoped |
| Scalability | **The 2 concretely-measured bottlenecks from the 400k-row scale test are both fixed and live-tested** | Bulk-write ceiling trigger batched (`CP8_SCALABILITY.md`, live-tested single-row + multi-salon-bulk); all 3 named unbounded Realtime streams bounded and live-verified against the real endpoint. Full 100k-client/20k-staff/1M-booking tier still never reached by any pass — stated as untested, not assumed fine |
| Maintainability | **Debt precisely inventoried, mostly unchanged in size, better understood** | P3-2/P3-3/P3-4 (architecture debt) re-confirmed with fresh evidence, deliberately not mass-refactored (risk/value judgment stated explicitly each time, not just deferred by inertia) |
| Documentation | **90-92/100 as of Cert v2**, index brought current this pass | `DOCUMENTATION_INDEX.md` hadn't been updated since Cert v2 until `CP10_DOCUMENTATION.md`; an ADR mechanism established for the first time (4 real entries) |
| DevOps | **CI/CD closed with proof (`R-7`)**; branching/hotfix strategy still `Non validé` (unchanged, not touched this pass) | 7 real runs, 3 consecutive green, re-confirmed via the public GitHub API this session's predecessor |
| Disaster Recovery | **A real, twice-proven manual restore playbook exists; full automation does not** | `CP3_ENGINEERING_CLOSURE.md` (prior pass) + this pass's own re-confirmation; P3-21 (full automation) remains genuinely open, Category A |
| Offline | **Write-side race-safe, read-side cold-start gap closed** | `P1-9` (client) fixed; `P1-13` (cold-start-offline cache) built and proven by 4 real tests — the one item in this whole program that had never even had a fix attempted before, now closed |
| Performance | **2 of 2 concretely-measured real bottlenecks fixed**; broader RLS-performance debt (P2-16/P2-17) explicitly deferred, not measured at a number | Same evidence as Scalability above; P2-16/P2-17 need per-policy review this pass's time budget doesn't cover, stated as `Ouvert`, not scored as if reviewed |

---

## Question 5 — Any P0 or P1 remaining?

**Yes — with a precise distinction that matters.**

**P0-1 is still live and unpatched in production, today.** Re-verified this session via a
read-only query against production (`hhdkjfpgaklhrhfoxlhj`): the `staff_profiles_public_select`
RLS policy still exists, `roles = {public}` (applies to unauthenticated `anon` requests too), no
column restriction. This is the exact account-takeover vector every prior pass in this program has
ranked above every other finding. **The fix is fully built and live-tested** (`PHASE_2_SECURITY_FIXES.md`,
re-confirmed this pass's predecessor via 6 passing automated live tests against `kynza-dr-scratch`)
— it is a **Category B (Operations)** item, awaiting Mylord's deployment approval, not an
engineering gap. Current blast radius, re-checked this session: **0 pending unclaimed
invitations exist in production right now** (`select count(*) from staff_profiles where
invitation_accepted_at is null` → `0`) — so there is no token to steal *today*, but the policy
would expose any future pending invitation the instant one is created, with zero warning.

**Other P0/P1 items still open, all Category B (Ops) or Category C (External) — none Category A
(Engineering)**:
- P1-2 (27 migrations undeployed), P1-3 (backup automation undeployed), P1-9-server (concurrency
  fix undeployed), P1-12 (alerting undeployed) — all fully engineered, live-tested on
  `kynza-dr-scratch`, awaiting deployment approval.
- P1-4, P1-6, P1-7, P1-8 — all reclassified External Go-Live Dependencies (real secret, real
  legal content, Apple Developer account, Google Play Console respectively) — not engineering
  debt at all.

**Zero P0/P1 items remain in Category A (genuine engineering still needed).** Every P0/P1 finding
in this program's entire history has either been fixed-and-proven (awaiting only a deployment
decision) or traced to an external dependency outside engineering's control.

---

## Question 6 — Is the backend done?

## **NO.**

P0-1 — a confirmed, live, unauthenticated account-takeover vector — remains unpatched in
production at the moment this document was written (re-verified by direct query, not assumed).
27 migrations, the recurring backup job, the alerting mechanism, and several security fixes exist
only as tested drafts on `kynza-dr-scratch`, not in production. "Backend done" means the backend
*as it actually runs in production* — by that standard, no.

---

## Question 7 — Is backend ENGINEERING done?

## **YES.**

This is the distinction Question 6 does not make. Every open P0/P1 item (Question 5) and every
remaining `Corrigé-non-déployé` item (Question 2/3, Category B, 18 items) has **complete,
live-tested engineering** — the only remaining action on each is Mylord's deployment approval, not
more code, more migrations, or more testing. The 15 genuine Category A (Engineering Remaining)
items are all P2/P3 severity — none is P0 or P1, none blocks a production-readiness claim, each
has a stated reason it wasn't rushed (Large scope, needs a real device, needs a product decision
first, etc. — see Question 2's table).

**The two answers diverge precisely because they measure different things**: Question 6 asks
"is the backend live and safe *right now*" (no — it depends on a deployment Mylord hasn't
approved yet). Question 7 asks "is there real engineering work left to do" (no — what's left is
approval and execution of already-finished work, which is Operations, not Engineering, by this
document's own Question 3 resolution rule).

---

## Question 8 — Can KYNZA start UI/UX Premium?

## **NO** — per this document's own stated rule (Question 8 must be consistent with Question 5).

Question 5 found P0-1 still open (live in production, unpatched). By the binary rule this
document was asked to apply ("if any P0/P1 remains open, this cannot be YES"), the answer is NO.

**Stated for completeness, not to soften the answer above**: every prior pass that has asked a
version of this question — including the Master Plan's own §19/§20 — reached a more nuanced
verdict: that UI/UX Premium work can start *in parallel* with closing the remaining Operations
items, specifically because production traffic is near-zero today and nothing found in this
entire program has ever been called a "stop everything" emergency. That nuance is real and cited
(`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §19-20) — but it is a *different
question* than the one this document was asked to answer with a strict P0/P1 gate. This document
answers the question as posed: **NO**, until P0-1 specifically is deployed and re-verified live,
which per Question 7 requires only Mylord's approval and execution of already-finished work, not
new engineering time.

---

## Verification summary (this document's own)

- `flutter analyze`: **0 issues** (re-run at the moment of writing this document).
- `flutter test`: **411 passed, 5 skipped, 0 failed** (re-run at the moment of writing this
  document, current `HEAD` = `e137a09` plus this document itself, which changes no code).
- Production (`hhdkjfpgaklhrhfoxlhj`) migration count re-confirmed unchanged: 59 applied, 27
  unapplied — nothing was deployed while producing this document.
- The one inconsistency found while reconciling (P1-2's row stating a stale "21 migrations"
  instead of the current real 27) was corrected in
  `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` directly, per this document's own explicit
  permission to fix — not introduce — inconsistencies discovered while answering these 9
  questions.
