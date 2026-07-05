# Zero Internal Engineering Debt — Final Declaration

**Date**: 2026-07-06. **Campaign**: Enterprise Final 100 (CP1-CP11), the closure pass over the
42 open/untested rows the Master Plan Execution pass left in the Master Inventory
(`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`).

## The direct declaration

**Zero internal engineering debt has NOT been reached.** 24 of the 42 open rows closed this pass
(19 with real proof, 5 reclassified as external dependencies once traced to one) — a genuine,
large reduction, not the whole distance. **18 rows still have open internal-engineering content.**
Overstating this as "done" would undo the credibility every prior pass in this program built by
being precise about exactly this distinction.

## The proof, not an assertion

Every row in the 68-row Master Inventory was re-counted directly from the table itself this
session (not estimated, not carried forward from memory) — see
`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s own updated tally line for the same
numbers, cross-checked here:

| Status | Count | Change this pass |
|---|---|---|
| `Fermé (preuve)` | 26 | +19 (was 7 closed before this pass: R-1 through R-7) |
| `Corrigé-non-déployé` | 17 | +3 net (P2-9, P2-11, P2-24 newly drafted+tested; several others reconfirmed unchanged) |
| `Corrigé, awaiting next release` (client-only) | 1 | unchanged (P1-10) |
| Reclassified `External Go-Live Dependency` (full row) | 6 | +6 (none were explicitly tagged external before this pass) |
| Split rows (external half + open internal half) | 2 | +2 (P2-21, P3-14) |
| `Ouvert` (genuinely open internal) | 15 | -19 (was 34 rows worth of pure-Ouvert content before, accounting for the split rows separately) |
| `Non validé` | 1 | -4 (P3-12, P3-16, P3-17, P3-19 closed with written verdicts) |
| **Total** | **68** | fixed |

**18 rows still carry open internal-engineering content** (15 `Ouvert` + 1 `Non validé` + the
internal half of the 2 split rows) — down from 42 at the start of this pass.

## Exactly what's still open internally, and why each wasn't rushed

| ID | What's open | Why it's still open, stated plainly |
|---|---|---|
| P2-10 | 19 of 24 repository_impl files still at 0% test coverage | The DI/mocking seam pattern is now proven (CP5, on ProxiPay) — applying it to the other 19 is real, repetitive, individually-careful work, genuinely Large, same judgment 2 prior passes already reached |
| P2-12 | Feature Flags engine gates nothing in the real app | Product decision (which features to flag-gate), not an engineering blocker |
| P2-14 | `check-subscription` cron doesn't exist | Genuine new Edge Function + cron needed, not attempted this pass |
| P2-16 | 83 `auth_rls_initplan` advisor warnings | Explicitly needs per-policy review across 49 tables, not a safe mechanical rewrite in the time available |
| P2-17 | 205 `multiple_permissive_policies` warnings | Same reasoning as P2-16, 23 tables |
| P2-21 (root/jailbreak half) | Detection code not shipped | A complete activation procedure exists; shipping unverified detection logic without a real rooted device to test against would violate this campaign's own governing rule |
| P2-25 | Storage bucket limits/MIME types, no WebP compression | Not attempted this pass — genuinely open, no reason beyond time budget |
| P3-2 / P3-3 | 14 presentation files bypass the repository layer; datasource split only real in `auth` | Reconfirmed with fresh evidence (CP1); a full refactor touches 14 live screens' core data paths for a documented Low-severity, non-blocking finding — the risk/value judgment doesn't favor rushing it, same as 3 prior passes |
| P3-4 | Router monolith, no `ShellRoute` | Already tracked in its own dedicated backlog with its own trigger condition — not re-litigated here |
| P3-5 | Edge Function hygiene (timeouts/metrics/tracing/structured logging) | A shared logging helper now exists and is proven on 2/22 functions (CP4) — full rollout is genuinely Large, same reasoning as P2-10 |
| P3-6 | 8 more unbounded repository methods | The exact fix pattern is now proven (CP8, on 3 sibling methods) but each of the 8 needs the same individual "does this one actually need a bound, or is unbounded intentional" check P2-23 got — deferred with a stated trigger: fix the next one that shows up in a real performance report |
| P3-7 | Offline outbox covers only 3 entities | By design, not a gap — re-stated for completeness, not actually open work |
| P3-10 | No formal support process / `CLIENT_SUPPORT` role | Product-scope decision, not blocked by any external dependency, just not decided |
| P3-14 (Analytics/local-notifications half) | Firebase Analytics not integrated; no local-notifications package | Not blocked externally (Firebase project already exists) — genuinely not attempted this pass |
| P3-18 | 2 of 4 CMS client-consumer screens not built | Small, mechanical, not attempted this pass |
| P3-20 | Rollback statements for the original 20-migration batch never live-drilled | The 5 *new* migrations added across this whole campaign all got their rollback DDL verified as part of writing it (simple `DROP`/`ALTER...DROP` reversals) — the original batch's more complex rollbacks remain undrilled, unchanged from the prior pass |
| P3-21 | Full backup-restore automation | A real, twice-proven **manual** restore playbook exists (Phase 0, Master Plan Execution CP3) — full one-click automation is a distinct, larger item, explicitly not attempted this pass (handling FK ordering and schema drift safely needs more than this pass's remaining time budget) |

## What would need to happen to reach true zero

1. Apply the proven repository-DI pattern (P2-10) to the remaining 19 repositories, and the
   proven structured-logging pattern (P3-5) to the remaining 20 Edge Functions — both are now
   templated, both are genuinely Large, multi-session efforts.
2. A dedicated per-policy RLS performance review (P2-16/P2-17) — not a blind rewrite, a real
   review of 49+23 tables' policies individually.
3. A rooted-device/emulator test pass for root/jailbreak detection (P2-21) — needs hardware this
   environment doesn't have.
4. Product decisions on P2-12, P2-14, P3-10, P3-18 (small-to-medium, mostly scoping, not
   technically hard).
5. A live rollback drill of the original 20-migration batch (P3-20) and a genuine automated
   restore mechanism (P3-21) — both real, both explicitly out of this pass's proportionate scope.

None of these are blocked on anything external — they're genuinely open internal engineering,
correctly not rushed.

## Cross-reference

Full evidence for every closed item: `docs/enterprise-final-100/CP1_ARCHITECTURE_BACKEND.md`
through `CP9_RELIABILITY.md`. External dependencies: `EXTERNAL_GO_LIVE_DEPENDENCIES.md`. Full
Master Inventory: `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 (updated in place).
