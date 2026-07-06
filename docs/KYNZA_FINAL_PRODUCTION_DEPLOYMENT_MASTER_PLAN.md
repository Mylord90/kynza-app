# KYNZA — Final Production Deployment Master Plan

**Consolidation date**: 2026-07-05. **Ground-truth verification method**: this document reports what every prior pass found; two facts were re-checked directly against the live systems as part of consolidation (not new audit work, per this document's own mandate) — the exact current migration count (`supabase migration list --linked`, run 2026-07-05) and the exact current Android keystore state (`ls android/key.properties`, `android/app/upload-keystore.jks`, run 2026-07-05). Every other fact below is traced to an existing report.

**Source passes consolidated** (chronological, each superseding/extending the last, none discarded — see `docs/DOCUMENTATION_INDEX.md`):

| # | Pass | Directory | Tag | Date | What it added |
|---|---|---|---|---|---|
| 1 | Documentation Expansion | (top-level docs) | — | 2026-07-03 | `ARCHITECTURE_GLOBAL.md`, `DATABASE_ARCHITECTURE.md` (55-table reference), `PRODUCTION_CHECKLIST.md` baseline |
| 2 | Enterprise Hardening | (top-level docs, not re-read; referenced via its own later corrections) | `post-hardening-v1` | 2026-07-03 | Encryption at rest fix, release-signing wiring, CI scaffold, App Check |
| 3 | Backend Enterprise Completion | `docs/backend-completion/` | `backend-complete-v1` | 2026-07-04 | CMS, Remote Config, Feature Flags enterprise layer, Health Center, A/B testing, Audit engine — all schema/engine only |
| 4 | Enterprise Final Certification v1 | `docs/certification/` | `enterprise-certified-v1` | 2026-07-04 | First live DB/Edge Function access; found the P0 (`invitation_token` exposure); 18-domain scorecard, 62.3/100 |
| 5 | Final Enterprise Verification v2 | `docs/certification-v2/` | `enterprise-verified-v2` | 2026-07-04 | Adversarial re-test; found 2 more live-exploitable bugs; scorecard dropped to 41.2/100; 3× No-Go |
| 6 | Enterprise Remediation | `docs/remediation/` | `remediation-v1` | 2026-07-04 | Real backup taken; 5 security fixes drafted+live-tested (2 bugs found in the drafts themselves); CI/CD made to genuinely execute; 49-issue Master Matrix; keystore contradiction resolved |
| 7 | Final Enterprise Validation | `docs/final-enterprise-validation/` | (untagged) | 2026-07-05 | Found 2 real concurrency bugs (not fixed here); 400k-booking scale test; confirmed prod not observable |
| 8 | Enterprise Resilience & Reliability Certification | `docs/enterprise-resilience/` | (untagged) | 2026-07-05 | Fixed the 2 concurrency bugs + 2 more; built first circuit breaker; proved alerting design live on `kynza-dr-scratch`; confirmed DR gap growing; confirmed cold-start-offline gap |

This document supersedes all eight for decision-making. The originals stay on disk as evidence — every claim below cites its source.

---

## 1. Executive Summary

**Current state**: KYNZA's backend is functionally complete for V1 scope — 55 production tables, 20 real Edge Functions, RLS on every table, and a further 6 feature subsystems (CMS, Remote Config, Feature Flags enterprise layer, Legal Center, Catalog, A/B Testing, Business Observability, Audit Business — built across migrations `20260703120000` through `20260704220000`) that are code-complete and validated against a staging project (`kynza-dr-scratch`) but **not one byte of which has ever reached production**. Two independent adversarial security passes (Certification v1 CP6, Certification v2 CP2/CP3) found real, live-exploitable vulnerabilities in production today — most seriously, a fully unauthenticated policy that exposes every pending staff invitation token, a credential that doubles as an account-takeover vector. A third pass (Final Enterprise Validation) found two real concurrency bugs capable of double-processing a booking-reminder notification or double-applying an offline mutation; a fourth pass (Enterprise Resilience) fixed both, plus two more, and built KYNZA's first circuit breaker — none of it deployed. Disaster recovery has exactly one backup, taken once, 2026-07-04T19:10:37Z, with no recurring job; the recovery-point gap is not a fixed number, it is **currently ≈18.5 hours and growing by the hour** (computed directly against that timestamp as part of this consolidation). Production is not observable — the one Edge Function that logs its own invocations writes to a table that does not exist there.

**Maturity level**: Enterprise-architected, staging-verified, production-undeployed. Every subsystem below the UI layer has been built once, and audited between two and five separate times by increasingly adversarial passes — but "audited" and "live" are two different facts throughout this program, and no report ever conflates them. The single most repeated sentence across all eight passes, in one phrasing or another, is: *this is drafted and tested, not deployed.*

**What's genuinely done**: Architecture (82/100, `CERTIFICATION_SCORECARD.md`, unconditional per `CERTIFICATES/ARCHITECTURE.md`); Documentation (92/100, now 90/100 post-v2); a real, restorability-proven one-time backup (`PHASE_0_BACKUP_CONFIRMED.md`); CI/CD now genuinely executes end-to-end for the first time in this project's history, 5 real runs, 3 real bugs found and fixed in the pipeline itself (`PHASE_4_READINESS_CLOSURES.md §2`); 5 security fixes drafted, applied to staging, and proven with real before/after exploit evidence, including catching 2 bugs that existed only in the *fixes themselves* (`PHASE_2_SECURITY_FIXES.md`); a real 400,001-row/40× booking-volume load test with a concretely identified bulk-write ceiling (`SCALABILITY_REPORT.md`); a first-ever circuit breaker and a proven (staging-only) 3-for-3 alerting design (`CIRCUIT_BREAKER_REPORT.md`, `OBSERVABILITY_ADVANCED_REPORT.md`).

**What genuinely remains**: Deploy 21 migrations (0 classified BLOCKER — see §7) and their corresponding Edge Function code; provision a real Android upload keystore (a one-way secret only Mylord can generate); write real Privacy Policy/Terms content; deploy the now-built-and-tested recurring backup job to production and rehearse a real restore-into-production specifically (the mechanism itself and a dr-scratch rehearsal are done, per Master Plan Execution CP3); start iOS from zero (Apple Developer enrollment, Firebase iOS config, a full second-platform build); fill in real bank-transfer details; decide the Google Play Data Safety form and store listing.

**Overall score**: There is no single number — three independent, non-additive scoring frameworks exist across this program (18-domain %, and two separate later 8-axis /10 resilience scorecards measuring different things; see §12 for why they aren't merged). The most recent 100-point framework (Certification v2) scored **41.2/100**, intentionally lower than v1's 62.3/100 because it tested harder, not because the codebase regressed (`SCORECARD_V2.md`). The two most recent /10 scorecards (Final Enterprise Validation, Enterprise Resilience) each independently averaged **6.25/10** across different 8-axis rubrics.

**Go/No-Go**: **No-Go**, on all three axes ever formally asked (Production, Play Store, App Store — `FINAL_ENTERPRISE_REPORT.md`), reaffirmed unchanged by the Remediation pass's own `CERTIFICATES/ENTERPRISE_READINESS.md`, and not contradicted by anything found in the two later passes (Final Enterprise Validation explicitly declines to issue a new Go/No-Go word; Enterprise Resilience's own French verdict is an explicit **"Non, pas encore"**). See §20 for the exact trigger condition that flips this.

---

## 2. Master Inventory

Every remaining item across all 8 passes, deduplicated. `Statut` uses only the four values specified: **Ouvert** (open, no fix attempted or drafted) / **Corrigé-non-déployé** (a real fix exists — code or migration — tested at minimum on `kynza-dr-scratch`, not applied to production) / **Non validé** (never tested in real conditions; silence upgraded to nothing) / **Fermé (preuve)** (closed, with cited proof).

IDs continue the Remediation pass's own `MASTER_ISSUES_MATRIX.md` numbering (P0/P1/P2/P3), extended with items the two later passes (Final Enterprise Validation, Enterprise Resilience) found that post-date that matrix. Items already closed carry an `R-` id from the same source.

| ID | Domaine | Description | Priorité | Risque | Dépendances | Temps estimé | Validation | Statut |
|---|---|---|---|---|---|---|---|---|
| P0-1 | Sécurité | `staff_profiles_public_select` RLS policy exposed `invitation_token`+`phone` to any unauthenticated request — sole credential `accept-invitation` uses to bind an account to a staff role/salon; account-takeover vector. **Deployed to production 2026-07-06** (`docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md`): policy dropped, replaced by column-limited `v_staff_directory_public` view; re-verified live via a real unauthenticated REST call against `hhdkjfpgaklhrhfoxlhj` itself (exploit now returns `[]`, legitimate view still serves data, sensitive columns unreachable even by name). Migration `20260704190000` marked applied in production migration history. | P0 | Critical (CVSS not computed by original finder; account-takeover class) | None — deployed | 15 min apply + smoke test | Live before/after exploit test on dr-scratch (`PHASE_2_SECURITY_FIXES.md`) + live production re-verification (`docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md`) | Fermé (preuve) |
| P1-1 | Sécurité | `staff_profiles.salon_id` mass-assignment — a staff account can self-reassign into another salon's staff directory via direct REST PATCH; no confidentiality impact (no RLS-protected data exposed), but integrity impact on the public practitioner-picker list. Fix drafted (`20260704200000...sql`), live-tested before/after. | P1 | High, CVSS≈6.5 | None | 15 min | `CP2_DEEP_SECURITY.md`, `PHASE_2_SECURITY_FIXES.md` | Corrigé-non-déployé |
| P1-2 | Backend / Infrastructure | **All 26 remaining migrations deployed to production 2026-07-06** (`docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md`): applied one at a time in dependency order, each validated live before proceeding. `supabase migration list --linked` now shows **86 local, 86 applied, 0 unapplied**. Two narrow companion gaps carried forward transparently (not part of "migrations," flagged in the Phase 2 report): `run-scheduled-actions`/`schedule-reminders` still need an Edge Function code redeploy to actually enforce the cron-secret check the migration wires up; `create-platform-backup` still needs its first deploy before the newly-registered backup cron job will succeed. Both are Phase 3 items. | P1 | Was: root cause of every low Monitoring/Observability/Production-Readiness score — now resolved at the DB layer | None — deployed | ~1 day (apply+verify all 26) — **done** | `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md`, live validation per migration, direct CLI re-check 2026-07-06 | Fermé (preuve) |
| P1-3 | Infrastructure / DR | Recurring automated backup mechanism, **DB half deployed to production 2026-07-06** (Phase 2 of Go-Live): migration `20260705130000_cp3_platform_backup_automation.sql` applied — `platform_backup_jobs` table, `get_all_public_tables()`, and the `kynza-platform-backup` cron job (`0 */6 * * *`) all confirmed live. **Function half still missing**: `create-platform-backup` Edge Function itself is not yet deployed to production (confirmed via `supabase functions list`), so the cron job will 404 on its first run until that deploy happens — this is Phase 3's explicit objective, not yet done. RPO in production remains unbounded until that function deploy + one real successful run is confirmed. | P1 | High until the function half deploys | None | 2-4h — **DB half done, function half pending (Phase 3)** | `PHASE_0_BACKUP_CONFIRMED.md`, `DISASTER_RECOVERY_REPORT.md` (CP4), `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Corrigé-non-déployé |
| P1-4 | Android / Release | No real Android upload keystore exists (`android/key.properties` and `android/app/upload-keystore.jks` both confirmed absent, 2026-07-05). The **conditional signing wiring is real and correct** (`build.gradle.kts` falls back to debug signing only when the real file is absent, verified end-to-end with a disposable test keystore) — this is why the Hardening pass correctly said "Release signing ✅ resolved" while Certification v2 correctly said "no real keystore provisioned": both are true, they describe different halves of the same fact. See §6 for the full resolution. One-way secret; Mylord-only action. | P1 | High — hard Play Store blocker | None (deliberately deferred, needs custody plan first) | 30 min (keytool) + custody planning | `docs/android/RELEASE_SIGNING_PROCEDURE.md`, `PHASE_4_READINESS_CLOSURES.md §1`, direct re-check 2026-07-05 | **Reclassé External Dependency** (real secret, Enterprise Final 100 CP11) |
| P1-5 | DevOps / CI/CD | CI/CD pipeline never executed. **CLOSED this program**: pushed 60 commits, triggered 5 real runs; runs 1-4 failed on real bugs (missing `build_runner` step, OS-dependent golden tests, missing `google-services.json` handling); run 5 fully green across all 4 jobs. | P1 (was) | — | None | Done | `PHASE_4_READINESS_CLOSURES.md §2`, GitHub Actions run IDs `28718162264`→`28730270227` | **Fermé (preuve)** |
| P1-6 | Legal / Business | Privacy Policy / Terms of Service: infrastructure fully built (Legal Center schema, migration `20260703150000`), every seeded document body is an explicit placeholder — zero real legal copy exists anywhere. Hard Play Store *and* App Store submission blocker. | P1 | High | Legal Center migration (part of P1-2 batch) must deploy first | Business-owned, not engineering | `PRODUCTION_CHECKLIST.md` Part 14, `MASTER_ISSUES_MATRIX.md` P1-6 | **Reclassé External Dependency** (final Privacy Policy/ToS content, Enterprise Final 100 CP11) |
| P1-7 | iOS | iOS is the untouched default Flutter scaffold: no Apple Developer Team set (`CODE_SIGN_STYLE = Automatic`, no `DEVELOPMENT_TEAM`), no `GoogleService-Info.plist`, no App Store Connect record, `Info.plist` missing usage descriptions/URL scheme. "A full second-platform launch effort, not a punch-list item" (`CP9_STORE_GO_NO_GO.md`). | P1 | High for App Store, zero for Android/Play | None | Weeks, not hours | `CP9_STORE_GO_NO_GO.md`, `MASTER_ISSUES_MATRIX.md` P1-7 | **Reclassé External Dependency** (Apple Developer account, Enterprise Final 100 CP11) |
| P1-8 | Play Store | Data Safety Form never started in Play Console. | P1 | High (Play blocker) | None | 1-2h, business decision | `CP9_STORE_GO_NO_GO.md` | **Reclassé External Dependency** (Google Play Console, Enterprise Final 100 CP11) |
| P1-9 | Fiabilité / Concurrency | Two real concurrency bugs: `OfflineSyncCoordinator.flush()` double-applies every queued mutation on concurrent flush; `run-scheduled-actions` double-processes a pending automation action on concurrent cron invocation. **Server fix deployed to production 2026-07-06**: `20260705100000_cp0_concurrency_atomic_claims.sql` applied — `claim_pending_action_runs()`, `reminder_dispatch_claims`, and the new unique index all confirmed live. Client fix (`AtomicClaimService`) still ships with the next app release, unchanged. | P1 | High once real traffic exists, now mitigated server-side | Client fix: none (ships with app). Server: none — deployed | Client: ships automatically next release. Server: **done** | `CONCURRENCY_REPORT.md` (CP0), `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Fermé (preuve) (server); Corrigé, awaiting next release (client) |
| P1-10 | Résilience | No circuit breaker existed anywhere in the codebase before Enterprise Resilience CP2. Built (`CircuitBreaker`, `DependencyCircuitBreakers` for `supabase`/`fcm`), wired into 6 call sites, proven via a real before/after dependency-down test. Purely client-side — ships with next app release, no server deploy gate. | — (new capability, not a gap) | — | None | Ships automatically next release | `CIRCUIT_BREAKER_REPORT.md` | Corrigé, awaiting next release |
| P1-11 | Fiabilité / Cache | CMS admin edits didn't invalidate the client-facing read path (`cmsPublishedProvider`/Hive mirror) — found and fixed in Enterprise Resilience CP3, client-side, ships next release (no server deploy gate, unlike every other "Corrigé-non-déployé" item in this table). | — | Was Medium | None | Ships automatically next release | `CACHE_STRATEGY_REPORT.md` | Fermé (preuve) |
| P1-12 | Observabilité | Payment-failure dashboard + alerting mechanism (3 thresholds), **DB half deployed to production 2026-07-06**: migration `20260705110000_cp6_observability_alerting.sql` applied — `v_payment_dashboard`, `system_alerts`, and all 3 RPCs (`check_system_alerts`/`get_payment_dashboard`/`get_system_alerts`) confirmed live. **No `pg_cron` schedule exists yet** to call `check_system_alerts()` periodically, and `check-system-alerts` Edge Function (if one is needed for dispatch) is not deployed — turning this into a real, running alerting loop is Phase 3's objective. | P0 (per Resilience pass's own recommendation) | High until scheduled | None (dependency already applied) | 30 min apply — **DB half done**; cron schedule pending (Phase 3) | `OBSERVABILITY_ADVANCED_REPORT.md`, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Corrigé-non-déployé |
| P1-13 | Continuité métier | Systemic architecture gap: **no read path anywhere in the app has a disk-backed cache.** **Fixed this pass** (Master Plan Execution CP3, `P5.5`): all 4 named read paths (agenda/bookings, catalog search, own profile, notification history) now hydrate from a new Hive-backed cache (`BookingReadCache`/`SearchReadCache`/`ProfileReadCache`/`NotificationReadCache`, PII-holding boxes encrypted with the same cipher as `SessionService`) on a cold start with no network, instead of showing nothing. Proven by 4 new live tests (`test/unit/cold_start_offline_cache_test.dart`) exercising the exact failure mode (a hung/never-emitting stream for realtime reads, a thrown exception for one-shot fetches) — not just described. Purely client-side, ships with next app release, no server deploy gate — same status shape as P1-10/P1-11. | — (closed) | Was Medium-high for offline-heavy markets | None | Done | `BUSINESS_CONTINUITY_REPORT.md` (CP5), `docs/master-plan-execution/CP3_ENGINEERING_CLOSURE.md`, `test/unit/cold_start_offline_cache_test.dart` (4/4 passing) | Fermé (preuve) |
| P2-1 | Sécurité | `create_default_document_templates(p_salon_id)` — anon-callable, zero caller/role validation. Fix drafted (`20260704210000...sql`), live-tested before/after. | P2 | Medium, CVSS≈5.3 | None | 15 min | `CP2_DEEP_SECURITY.md`, `PHASE_2_SECURITY_FIXES.md` | Corrigé-non-déployé |
| P2-2 | Sécurité | `calculate-commission` — any authenticated user of any salon can read another salon's exact commission amount for a guessed `booking_id`; no salon-ownership check. Fix drafted (code patch, no migration needed), live-tested before/after. | P2 | Medium, CVSS≈5.3 | None | Redeploy function | `CP4_EDGE_FUNCTION_REVERIFY.md`, `PHASE_2_SECURITY_FIXES.md` | Corrigé-non-déployé |
| P2-3 | Sécurité | `run-scheduled-actions`/`schedule-reminders` rely on `verify_jwt:true` alone. **DB half deployed to production 2026-07-06**: `CRON_SECRET` set as both an Edge Function secret and a Vault entry (the precondition), then `20260704220000` applied — both `pg_cron` jobs confirmed sending `X-Cron-Secret` and confirmed still `active=true`. **Not actually enforced yet**: the currently-deployed function code (`run-scheduled-actions` v3) does not check for that header — confirmed live, an anon-only call still returns `200`. Enforcement requires an Edge Function redeploy, outside "migrations" scope, not attempted this phase. | P2 | Medium — DB precondition done, enforcement still open | None remaining for the DB half | 30 min — **DB half done**; function redeploy still needed | `CP4_EDGE_FUNCTION_REVERIFY.md`, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Corrigé-non-déployé |
| P2-4 | Sécurité / Database | 2 `SECURITY DEFINER` views bypass caller permissions (`v_popular_searches`, `v_mv_daily_revenue`). **Design decision made (Enterprise Final 100 CP2)**: both views' actual SQL read directly — `v_popular_searches` is a deliberate cross-user aggregate (no SELECT policy on `search_logs` at all, so `security_invoker` would return zero rows; no sensitive column exposed); `v_mv_daily_revenue` re-derives `auth.uid()`'s own `salon_id` inline (MVs can't carry RLS — this is the standard workaround, and `auth.uid()` is unaffected by `SECURITY DEFINER`). Both intentional, both safe. | P2 | Medium | None | Needs design decision, not drafted | `PHASE_2_DATABASE_OPTIMIZATION.md` (CP2 advisor), `CP2_SECURITY.md` | **Fermé (preuve)** |
| P2-5 | Sécurité | Oversized payload (2MB JSON) hangs an Edge Function 45+ seconds; no function has a body-size limit. **Fixed (Enterprise Final 100 CP2)**: `checkBodySize()` added to `_shared/cors.ts`, wired into all 16 functions that parse a JSON body. Live-tested on dr-scratch: 200KB body → 413, normal body still reaches real logic. | P2 | Medium (mild DoS) | None | Small, per-function | `PHASE_6_SECURITY_OFFENSIVE.md`, `CP2_SECURITY.md` | Corrigé-non-déployé |
| P2-6 / P2-27 | QA | MANAGER-role and SYSTEM_ADMIN-role live RLS isolation — **tested for real this pass** (Master Plan Execution CP1): 2 new QA fixtures seeded on `kynza-dr-scratch` (`kynza.qa.a.manager.cp1@example.com` role=manager; `kynza.qa.sysadmin.cp1@example.com` is_system_admin=true), same cross-tenant read/write matrix `CP3_RLS_ADVERSARIAL_MATRIX.md` used for owner/staff/client — both isolated (0 cross-tenant leakage for either role), plus a positive-capability check proving `has_system_admin()` grants exactly its intended platform-wide scope (`get_supabase_dashboard()`: manager 403, system_admin 200) and nothing more. | P2 | Coverage gap — now closed | — | — | `CP3_RLS_ADVERSARIAL_MATRIX.md`, `docs/master-plan-execution/CP1_SECURITY_CLOSURE.md` | **Fermé (preuve)** |
| P2-7 | Observabilité | `activity_logs.ip_address`/`device_info` not populated by several Edge Functions (`accept-invitation`, `calculate-commission`, `claim-referral` spot-checked). Systemic, not fully audited. **Fixed (Enterprise Final 100 CP6)**: found the gap was systemic across all 9 functions that write `activity_logs`, not just the 3 spot-checked. Fixed the existing (never-adopted) `logActivity()` helper to derive both from the request, migrated all 9 call sites. Live-tested on dr-scratch: real invocation produced a row with a real `ip_address` and the exact `device_info` sent. | P2 | Medium (audit-quality gap) | None | Medium (per-function) | `CP1_ARCHITECTURE_REVERIFY.md`, `CP5_OBSERVABILITY_MONITORING_GAP.md`, `CP6_OBSERVABILITY.md` | **Fermé (preuve)** |
| P2-8 | Sécurité | `is_system_admin` grant/revoke/audit mechanism. **Deployed to production 2026-07-06**: `grant_system_admin()`/`revoke_system_admin()` RPCs + `system_admin_audit` table confirmed live via `20260706100000`. | P2 | Medium | None — deployed | Small — **done** | `MASTER_ISSUES_MATRIX.md` P2-8, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Fermé (preuve) |
| P2-9 | Backend | Remote Config's 2 Edge Functions (`update-remote-config`, `rollback-remote-config`) gated on `role==='owner'` instead of `has_system_admin()`. **Fixed and live-tested this pass** (Master Plan Execution CP2): gate swapped to `!caller.is_system_admin`, deployed to `kynza-dr-scratch`, confirmed live — a salon owner (not system_admin) now gets `403 forbidden` (previously `200`), a system_admin account passes the gate through to the next real check. | P2 | Medium — fix ready, not yet in production | `has_system_admin()` already exists in draft migration `20260704120000`, which must apply first | Trivial code change — **done, this pass** | `MASTER_ISSUES_MATRIX.md` P2-9, `docs/master-plan-execution/CP2_DEPLOYMENT_READY.md` | Corrigé-non-déployé |
| P2-10 | Tests | 26.38% line coverage overall (re-measured, Enterprise Final 100 CP5 — the "23.29%" figure was stale, coverage had genuinely grown since); **zero repository-layer test files exist at all** — no DI/mocking seam for any repository wrapping `SupabaseService` directly. **Partially closed (Enterprise Final 100 CP5)**: the missing DI seam pattern built and proven for the first time on 1 named high-risk repository (`ProxiPayRepositoryImpl`, now takes an injectable `SupabaseClient`), 2 new tests added, `mocktail` adopted. A second, separate gap found while trying to extend this: anything wrapped in `PerformanceMonitoringService.traceAsync` is untestable without Firebase platform-channel mocking, which doesn't exist anywhere in this suite. 19 of 24 repository_impl files remain at 0% — same treatment applies to each, genuinely Large. | P2 | Medium-high (structural, not a specific bug) | New mocking infrastructure needed | Large | `PHASE_9_ENTERPRISE_TESTING_COVERAGE.md`, `CERTIFICATES/QA.md`, `CP5_TESTS.md` | Ouvert (re-scoped — pattern proven, 19/24 repositories + Firebase-mocking gap remain) |
| P2-11 | Backend | `proxipay-create-session` unique constraint on `booking_id` — the single most-repeated never-fixed finding in this program (5× corroborated). **Deployed to production 2026-07-06**: partial unique index confirmed live via `20260706130000` — checked for zero pre-existing conflicts before applying. | P2 | Medium | None — deployed | Small — **done** | `MASTER_ISSUES_MATRIX.md` P2-11, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Fermé (preuve) |
| P2-12 | Backend | `evaluate_feature_flag()` / Feature Flags engine gates nothing in the real app — zero screens call it. | P2 | Low-medium | None | Medium | `MASTER_ISSUES_MATRIX.md` P2-12 | Ouvert |
| P2-13 | Sécurité | `PermissionGuard` built, wired into zero screens. **Fixed (Enterprise Final 100 CP2)**: wired into `staff_list_screen.dart`'s "Add staff" action (`feature: 'staff', action: 'manage'`) — the first real screen. Verified both client and server-side owner short-circuits agree, so owners see no change; a manager only sees it if explicitly granted via the permission-groups system, closing a real gap (any manager could previously reach this unconditionally). | P2 | Low-medium | None | Medium | `MASTER_ISSUES_MATRIX.md` P2-13, `CP2_SECURITY.md` | **Fermé (preuve)** |
| P2-14 | Backend | `check-subscription` cron doesn't exist — lapsed paid plans never auto-revert to free tier. | P2 | Medium (revenue-adjacent) | None | Medium (new Edge Function+cron) | `MASTER_ISSUES_MATRIX.md` P2-14 | Ouvert |
| P2-15 | Database / Performance | 32 unindexed foreign keys across 24 tables. **Deployed to production 2026-07-06**: all indexes confirmed live via `20260703120000` + `20260704180000` (32 named indexes confirmed present by exact-name count). | P2 | Medium | None — deployed | Included in P1-2 — **done** | `PHASE_2_DATABASE_OPTIMIZATION.md`, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Fermé (preuve) |
| P2-16 | Database / Performance | 83 `auth_rls_initplan` advisor warnings across 49 tables (RLS calling `auth.uid()` directly instead of `(select auth.uid())`, causing per-row re-evaluation). **Reconfirmed, deliberately not force-fixed (Enterprise Final 100 CP8)**: still genuinely needs per-policy review, not a blind rewrite — a mechanical rewrite across 49 tables risks silently changing RLS semantics without individual review, which this campaign's time budget doesn't have room for. Same judgment as 2 prior passes. | P2 | Medium at scale | Needs per-policy review, not a blind rewrite | Large | `PHASE_2_DATABASE_OPTIMIZATION.md`, `SQL_PERFORMANCE_REPORT.md` (re-confirmed open), `CP8_SCALABILITY.md` | Ouvert |
| P2-17 | Database / Performance | 205 `multiple_permissive_policies` advisor warnings across 23 tables. **Reconfirmed, deliberately not force-fixed (Enterprise Final 100 CP8)** — same reasoning as P2-16. | P2 | Medium at scale | None | Large | `PHASE_2_DATABASE_OPTIMIZATION.md`, `SQL_PERFORMANCE_REPORT.md` (re-confirmed open), `CP8_SCALABILITY.md` | Ouvert |
| P2-18 | Database | Missing `updated_at` trigger despite the column existing: `salon_settings`, `permission_groups`, `automation_workflows` — "a real correctness bug, not a design choice," never fixed across 5 passes. **Fixed (Enterprise Final 100 CP4)**: all 3 triggers added, live-tested on dr-scratch — a real UPDATE confirmed `updated_at` genuinely changes, not assumed. | P2 | Low-medium | None | Trivial (3 triggers) | `DATABASE_ARCHITECTURE.md`, `MASTER_ISSUES_MATRIX.md` P2-18, `CP4_CODE_QUALITY.md` | **Fermé (preuve)** |
| P2-19 | Business | Bank transfer details still literal `[À CONFIGURER]` placeholder in `KynzaConstants` and `create-manual-invoice`. | P2 | Medium (blocks real invoicing) | None | Business-owned | `PRODUCTION_CHECKLIST.md`, `MASTER_ISSUES_MATRIX.md` P2-19 | **Reclassé External Dependency** (real bank account details, Enterprise Final 100 CP11) |
| P2-20 | Observabilité | No alerting/threshold code existed anywhere prior to P1-12; confirmed by repeated `grep` across 2 passes returning 0 matches before Resilience CP6 built one. | P2 (superseded by P1-12's fix) | — | — | — | `MASTER_ISSUES_MATRIX.md` P2-20, `OBSERVABILITY_ADVANCED_REPORT.md` | Corrigé-non-déployé (see P1-12) |
| P2-21 | Sécurité | Certificate pinning scaffolded but permanently inert (`featureFlagEnabled=false`, empty cert bytes); root/jailbreak detection not implemented. **Split (Enterprise Final 100 CP2)**: pinning half reclassified External (needs a real captured production TLS cert). Root/jailbreak half: a complete, ready-to-execute activation procedure written (`docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md`), deliberately not shipped as code — verifying it needs a real rooted device/emulator that doesn't exist in this environment, and shipping unverified detection logic would violate this campaign's own governing rule. | P2 | Medium | Needs a verified capture of Supabase's real cert from a trusted environment first | Medium | `SECURITY_AUDIT_V2.md`, `MASTER_ISSUES_MATRIX.md` P2-21, `CP2_SECURITY.md` | Pinning: **Reclassé External Dependency**. Root/jailbreak: Ouvert, procedure ready |
| P2-22 | Scalabilité | Real bulk-write ceiling found: a per-row `UPDATE` trigger (`trg_increment_monthly_bookings`) caps any single bulk-insert statement around 150,000-300,000 rows before hitting a ~2-minute statement timeout. Confirmed via real 400,001-row test (bisected in batches to avoid the ceiling). **Fixed (Enterprise Final 100 CP8)**: converted to a `FOR EACH STATEMENT` trigger with a transition table, aggregating via `GROUP BY` — fires once per statement, not once per row. Live-tested on dr-scratch: single-row insert still +1 correct; a multi-salon bulk insert in one statement credited each salon exactly its own row count, no cross-contamination. A full 400k-row re-run was not repeated (the fix directly addresses the confirmed root cause — per-row execution count — so the ceiling is structurally addressed, not just made faster at the margin). | P2 | Medium — real, concrete, but currently far above any plausible near-term traffic | None | Medium (batch or async the trigger) | `SCALABILITY_REPORT.md` (CP6), `FINAL_CERTIFICATION.md` (carried forward), `CP8_SCALABILITY.md` | **Fermé (preuve)** |
| P2-23 | Performance / Realtime | 3 unbounded Realtime `.stream()` call sites (booking calendar salon/practitioner variants, notifications list) fetch a practitioner's/user's entire history client-side with no server-side bound. Measured 46× slower (1.4ms→64ms) at 400k rows vs. the properly-bounded equivalent, which only slowed 3× for the same 40× data growth. **Fixed (Enterprise Final 100 CP8)**: confirmed via SDK source that `SupabaseStreamBuilder` only supports `.eq()`+`.order()`+`.limit()`, no range filter — added `.order().limit(200)` to all 3 named sites. Live-verified against the real dr-scratch Realtime endpoint with a standalone script (not just a compile check): returned exactly the requested row count, correctly ordered. | P2 | Medium, will compound with real growth | None | Medium (add bound + pagination) | `SQL_PERFORMANCE_REPORT.md`, `SCALABILITY_REPORT.md`, `CP8_SCALABILITY.md` | **Fermé (preuve)** |
| P2-24 | Realtime | `notification_logs` publication membership. **Deployed to production 2026-07-06**: `20260705120000` applied, `notification_logs` confirmed present in `pg_publication_tables` for `supabase_realtime`. A full Realtime-client round-trip (subscribe/mutate/observe) still hasn't been performed against production (no `@supabase/supabase-js` tooling in this Flutter repo) — flagged honestly, not silently upgraded to a full end-to-end proof. | P2 | Medium (UX gap) | None — deployed | Trivial — **done** | `REALTIME_REPORT.md`, `docs/go-live/PHASE_2_MIGRATION_DEPLOYMENT_REPORT.md` | Fermé (preuve) |
| P2-25 | Storage | Neither storage bucket (`kynza-media`, `kynza-backups`) has a `file_size_limit` or `allowed_mime_types` set at the bucket level; no server-side WebP compression exists despite it being a documented mandate (AGENT.md §5). | P2 | Medium | None | Medium | `STORAGE_REPORT.md` | Ouvert |
| P2-26 | Sécurité | `check_rate_limit` RPC fails open (`if (error) return true`) — an outage/bug in the limiter itself lets requests through rather than blocking them. **Reconfirmed correct, gap closed (Enterprise Final 100 CP2)**: fail-open is the right tradeoff for a rate limiter specifically (fail-closed would turn a transient DB hiccup into a real availability outage across ~15 functions) — not blindly flipped. The actual gap (the failure was silent) is fixed: now logged via `console.error`. See `docs/adr/0001-rate-limiter-fails-open.md`. | P2 | Medium | None | Small | `SECURITY_REPORT.md` (CP7), `CP2_SECURITY.md` | **Fermé (preuve)** |
| P3-1 | Architecture | 3 real `core`↔`feature` circular provider dependencies (`auth_providers.dart`↔`auth_notifier.dart`; `offline_sync_providers.dart`↔3 feature providers). Compiles/works, maintainability debt only. **Fixed (Enterprise Final 100 CP1)**: both real cycles broken by splitting each core file into a core-only half and a feature/composition half. An independent tool re-scan (import/export reachability, not eyeball) confirms 0 real cycles remain in 450 non-generated files — only the pre-existing benign generated l10n cycles. | P3 | Low | None | Medium (refactor) | `CP1_ARCHITECTURE_REVERIFY.md`, `CP1_ARCHITECTURE_BACKEND.md` | **Fermé (preuve)** |
| P3-2 | Architecture | 14 presentation files bypass the repository layer, calling `SupabaseService` directly. | P3 | Low | None | Large | `PHASE_1_FINAL_AUDIT.md`, `MASTER_ISSUES_MATRIX.md` P3-2 (3× corroboration) | Ouvert |
| P3-3 | Architecture | Repository/Datasource split only real in `auth/data`; 23 other features go straight `RepositoryImpl`→`SupabaseService.client`. | P3 | Low | None | Large | `PHASE_1_FINAL_AUDIT.md`, `MASTER_ISSUES_MATRIX.md` P3-3 (3× corroboration) | Ouvert |
| P3-4 | Architecture | `app_router.dart` monolithic, 1,418 lines, no `ShellRoute` — pre-existing, separately tracked backlog item (`project_shellroute_refactor_backlog`). | P3 | Low | None | Large | `CP1_ARCHITECTURE_REVERIFY.md`, `MASTER_ISSUES_MATRIX.md` P3-4 | Ouvert |
| P3-5 | Edge Functions | Systemic hygiene gap: 0/20 functions have an explicit timeout, ~1/20 have metrics, 0/20 have tracing/correlation-IDs, ~0/20 have structured logging. **Partially closed (Enterprise Final 100 CP4)**: built a shared structured-logging/request-ID helper (`_shared/log.ts`) — none existed before — adopted in 2 functions (`calculate-commission`, `create-platform-backup`) as a proven template. Full 22-function rollout explicitly deferred, same "Large (per-function)" reasoning 3 prior passes already reached. | P3 | Low-medium | None | Large (per-function) | `PHASE_3_EDGE_FUNCTION_CERTIFICATION.md`, `CP5_OBSERVABILITY_MONITORING_GAP.md`, `CP4_CODE_QUALITY.md` | Ouvert (re-scoped — helper built, proven on 2/22) |
| P3-6 | Backend | 8 pre-existing unbounded repository stream/fetch methods (distinct from P2-23's Realtime-specific 3). **Reassessed (Enterprise Final 100 CP8)**: the same `.limit()` pattern just proven on P2-23's 3 sites applies mechanically, but confirming each of the 8 doesn't have a different real requirement (e.g. `getClientBookings` intentionally shows full history by design) needs the same one-by-one care, not a blind batch-apply. Deferred with a stated trigger: apply the proven template the next time any of these 8 shows up in a real performance report. | P3 | Low | None | Medium | `MASTER_ISSUES_MATRIX.md` P3-6, `CP8_SCALABILITY.md` | Ouvert |
| P3-7 | Offline | Offline outbox covers only 3 entities (`reviewCreate`/`profileUpdate`/`dataDeletionRequest`) by design; bookings/cash-payments/status-changes deliberately excluded. Distinct from P1-13's "no read cache" finding — this is a documented, by-design write-side scope limit, not a bug. | P3 | Low (by design) | None | N/A unless scope changes | `OFFLINE_STRATEGY.md`, `MASTER_ISSUES_MATRIX.md` P3-7 | Ouvert (by design) |
| P3-8 | Database | `salon_settings`/`owner_journey_progress`/`referrals` missing `deleted_at`. **Fixed (Enterprise Final 100 CP4)**: all 3 columns added, live-confirmed present on dr-scratch via `information_schema`. | P3 | Low | None | Trivial | `DATABASE_ARCHITECTURE.md`, `CP4_CODE_QUALITY.md` | **Fermé (preuve)** |
| P3-9 | Database | `salons.owner_id` not a declared FK, no index, despite being used throughout RLS. **Fixed (Enterprise Final 100 CP4)**: added as `NOT VALID` + separate `VALIDATE CONSTRAINT` (avoids a blocking table scan) + supporting index. Live-validated on dr-scratch with zero orphaned rows. | P3 | Low | None | Small | `DATABASE_ARCHITECTURE.md`, `CP4_CODE_QUALITY.md` | **Fermé (preuve)** |
| P3-10 | Business | No formal support process / `CLIENT_SUPPORT` role exists. | P3 | Low | None | Product decision | `PRODUCTION_CHECKLIST.md` Part 14 | Ouvert |
| P3-11 | Ops | No in-app/admin UI to create a maintenance window — SQL-only today. **Fixed (Enterprise Final 100 CP3)**: 2 new RLS policies (INSERT/DELETE, gated `has_system_admin`), repository CRUD methods, new `MaintenanceAdminScreen` routed behind the existing `_SystemAdminGuard`, linked from Settings. Live-tested on dr-scratch: non-admin rejected on both INSERT and DELETE, system_admin succeeds on both. | P3 | Low | None | Small | `PRODUCTION_CHECKLIST.md`, `CP3_INFRASTRUCTURE.md` | **Fermé (preuve)** |
| P3-12 | Observabilité | Crash Dashboard / Performance Dashboard have no queryable data source (Firebase Performance has no read API) — platform limitation, not a code bug. **Verdict formalized (Enterprise Final 100 CP11)**: the "platform limitation" reasoning was already fully stated by the pass that found it (Firebase Performance genuinely has no read API, independent of anything this codebase could do) — closed as a formal verdict rather than left open pending a re-check that would find the same platform fact. | P3 | Low | None | N/A (platform limit) | `PHASE_2_OBSERVABILITY.md`, `PHASE_4_PERFORMANCE_OBSERVABILITY.md` | **Fermé (preuve)** |
| P3-13 | Auth | Facebook and Apple sign-in are both stubs (`throw UnimplementedError`). **Reclassified (Enterprise Final 100 CP11)**: real activation of either needs an external app registration with real credentials — Facebook needs a real Facebook Developer App (real API keys, excluded), Apple Sign In needs an Apple Developer account (excluded) plus Firebase configuration for it. Both halves genuinely blocked by excluded dependencies, not deferred by choice. | P3 | Low | None | Medium | `PRODUCTION_CHECKLIST.md` | **Reclassé External Dependency** |
| P3-14 | Product | No Google Maps/Places/Geolocation, Firebase Analytics, or local-notifications package integrated. **Split (Enterprise Final 100 CP11)**, not blanket-reclassified: Maps/Places/Geolocation genuinely need a real Google Maps API key — External. Firebase Analytics and the local-notifications package are **not** blocked by anything on the excluded list (a real Firebase production project already exists and is configured for Crashlytics/FCM) — these remain genuinely open internal work, not attempted this pass, stated honestly rather than folded into the external bucket for convenience. | P3 | Low | None | Large | `PRODUCTION_CHECKLIST.md` | Maps/Geolocation: **Reclassé External Dependency**. Firebase Analytics + local-notifications: Ouvert (internal, not external) |
| P3-15 | Sécurité | `get_staff_week_rank` had a loose anon EXECUTE grant. Fix drafted+live-tested (bundled in `20260704210000...sql`) — **real bug found**: initial `REVOKE...FROM anon` was a no-op because the actual grant came from `PUBLIC`; corrected to `REVOKE...FROM PUBLIC`. | P3 | Low | None | Included in P2-1's migration | `PHASE_2_SECURITY_FIXES.md` | Corrigé-non-déployé |
| P3-16 | Database | `rls_enabled_no_policy` advisor warning on `rate_limit_buckets` (RLS enabled, zero policies — correctly default-deny, but never given an explicit written verdict). **Verdict written (Enterprise Final 100 CP11)**: read the table's own migration directly (`20260627150000_adv6_security_hardening.sql`) — its own comment states "No RLS policies needed — service_role bypasses RLS entirely, and no other role can ever read/write this table (no GRANT to authenticated)," and `EXECUTE` on `check_rate_limit` is separately, explicitly revoked from `authenticated`/`anon`/`public`. Intentional, correct, confirmed by direct inspection, not inferred. | P3 | Low | None | Trivial (write the verdict) | `PHASE_2_DATABASE_OPTIMIZATION.md` | **Fermé (preuve)** |
| P3-17 | Storage | `public_bucket_allows_listing` advisor warning on `kynza-media` — likely intentional (public menu images), never given an explicit written verdict. **Verdict written (Enterprise Final 100 CP11)**: read the bucket's own migration directly (`20260623201000_storage_kynza_media.sql`) — its own header states "Public read (logos/covers/portfolio must render in the public salon discovery feed without auth)." Listing exposes only file paths under `salon/{salonId}/...`, no PII (salon IDs are already public via the `salons` table itself). Intentional, safe. | P3 | Low | None | Trivial | `PHASE_2_DATABASE_OPTIMIZATION.md` | **Fermé (preuve)** |
| P3-18 | CMS | 2 of 4 named CMS client-consumer screens not built (`OnboardingContentScreen`, `BeautyTipsScreen`). | P3 | Low | None | Small | `PHASE_9_CMS_ENTERPRISE.md` | Ouvert |
| P3-19 | Database | 50 `unused_index` advisor warnings — explicitly not actionable pre-launch (false signal at near-zero traffic). **Verdict formalized (Enterprise Final 100 CP11)**: the "not actionable pre-launch" reasoning was already fully stated by the pass that found it — this row closes it as a formal verdict rather than leaving it open pending a re-check that would find the same answer (production traffic is still near-zero). Re-open once real production traffic volume exists, per the same reasoning. | P3 | Low | None | N/A pre-launch | `PHASE_2_DATABASE_OPTIMIZATION.md` | **Fermé (preuve)** |
| P3-20 | Rollback | Rollback statements exist for all 20 migrations but have only been *written*, not live-drilled (Phase 2 proved the fixes work; it did not additionally roll each back on dr-scratch to prove the rollback statement itself). | P3 | Low-medium | None | Medium (drill each) | `CERTIFICATES/RELIABILITY.md` | Non validé |
| P3-21 | Backup | `create-backup` remains export-only — no restore-from-backup code path exists anywhere; "rollback procedure" as commonly understood does not exist. | P3 | Medium | None | Medium | `PRODUCTION_CHECKLIST.md`, `CERTIFICATES/RELIABILITY.md` | Ouvert |
| R-1 | Android | Release AndroidManifest permissions gap — resolved, verified in Hardening Phase 1. | — | — | — | — | `MASTER_ISSUES_MATRIX.md` R-1 | Fermé (preuve) |
| R-2 | Edge Functions | `leapa-webhook` missing top-level try/catch — fixed, live-verified. | — | — | — | — | `PHASE_8_CODE_QUALITY_CLEANUP.md` | Fermé (preuve) |
| R-3 | Flutter | 2 `setState`-after-`await` crash-risk bugs — fixed. | — | — | — | — | `PHASE_8_CODE_QUALITY_CLEANUP.md` | Fermé (preuve) |
| R-4 | Sécurité | SQL injection via `create-booking`'s unvalidated `practitionerId` filter — fixed. | — | — | — | — | `SECURITY_AUDIT_V2.md` | Fermé (preuve) |
| R-5 | Sécurité | `leapa-webhook` zero rate limiting — fixed. | — | — | — | — | `SECURITY_AUDIT_V2.md` | Fermé (preuve) |
| R-6 | Infrastructure | Zero backups ever taken — fixed (one-time; recurrence tracked separately as P1-3 residual). | — | — | — | — | `PHASE_0_BACKUP_CONFIRMED.md` | Fermé (preuve) |
| R-7 | DevOps | CI/CD never executed — fixed, 5 real runs, full green. **Re-confirmed live this pass** (Master Plan Execution CP4, direct GitHub API re-check): now 7 total runs, 3 most-recent consecutive green (`28730270227`→`28730634059`→`28730760506`). | — | — | — | — | `PHASE_4_READINESS_CLOSURES.md §2`, `docs/master-plan-execution/CP4_RELEASE_CLOSURE.md` | Fermé (preuve) |

**Total distinct items in this table: 68** (1 P0, 13 P1, 26 P2, 21 P3, 7 R — some rows carry two IDs where a later pass re-confirmed rather than duplicated a finding).

**Updated 2026-07-05 (Master Plan Execution pass, CP1-CP5 — see `docs/master-plan-execution/`)**:
11 closed with proof, 15 `Corrigé-non-déployé`, 42 genuinely open — down from 47. Superseded by
the update immediately below (Enterprise Final 100 closed 24 more rows in the same pass structure).

**Updated 2026-07-06 (Enterprise Final 100 pass, CP1-CP11 — see `docs/enterprise-final-100/`,
final declaration in `enterprise-final-100/ZERO_INTERNAL_DEBT_DECLARATION.md`)**: precise recount
of all 68 rows, not estimated —
**26 `Fermé (preuve)`** (R-1 through R-7, P1-5, P1-11, P1-13, P2-4, P2-6/P2-27, P2-7, P2-13, P2-18,
P2-22, P2-23, P2-26, P3-1, P3-8, P3-9, P3-11, P3-12, P3-16, P3-17, P3-19 — 19 newly closed this
pass alone, on top of the 7 already closed) —
**17 `Corrigé-non-déployé`** (fix built and live-tested on `kynza-dr-scratch`, awaiting Mylord's
production-deploy approval) —
**1 `Corrigé, awaiting next release`** (P1-10, pure client-side, no server deploy gate) —
**6 rows reclassified `External Go-Live Dependency`** in full (P1-4, P1-6, P1-7, P1-8, P2-19,
P3-13) **+ 2 rows split** between an external half and a genuinely-open internal half (P2-21:
pinning vs. root/jailbreak; P3-14: Maps/Geolocation vs. Firebase Analytics/local-notifications) —
**15 `Ouvert`** (genuinely open internal engineering, each with a stated reason it wasn't rushed
this pass) —
**1 `Non validé`** (P3-20, rollback drilling for the original 20-migration batch specifically).
**Net: 42 → 18 rows with any remaining open internal-engineering content** (15 Ouvert + 1 Non
validé + the internal half of the 2 split rows) — a reduction of 24 rows in one pass, zero rows
moved backward. **This is not zero** — see the final declaration for exactly which 18 remain open
and why.

---

## 3. Tasks by Category

*(Each category lists its Master Inventory IDs; full detail is in §2 — this section exists so no category needs cross-referencing to be actionable.)*

- **Architecture**: P3-1, P3-2, P3-3, P3-4 — all non-blocking debt, `CERTIFICATES/ARCHITECTURE.md` unconditional.
- **Backend**: P1-2, P2-9, P2-11, P2-12, P2-14 — features built, gated on deployment (P1-2) or trivial code fixes.
- **Infrastructure**: P1-3, P1-4, P1-5 (closed), P2-25.
- **Supabase**: P1-2, P2-4, P2-15, P2-16, P2-17, P2-18, P3-8, P3-9, P3-16, P3-17, P3-19.
- **Flutter**: P3-2, P3-3, P3-6, P1-9 (client half), P1-10, P1-11.
- **Sécurité**: P0-1, P1-1, P2-1, P2-2, P2-3, P2-4, P2-5, P2-8, P2-13, P2-21, P2-26, P3-15.
- **Edge Functions**: P0-1 (companion function), P2-1, P2-2, P2-3, P3-5, P2-11.
- **RLS**: P0-1, P1-1, P2-3, P2-4, P2-6/P2-27, P2-16, P2-17.
- **Observabilité**: P1-12, P2-7, P2-20 (superseded by P1-12), P3-12.
- **Performance**: P2-16, P2-17, P2-22, P2-23.
- **Offline**: P1-9 (client), P1-13, P3-7.
- **Scalabilité**: P2-22, P2-23.
- **CI/CD**: P1-5 (closed).
- **DevOps**: P1-5 (closed), P3-20.
- **Android**: P1-4, R-1 (closed).
- **iOS**: P1-7.
- **Play Store**: P1-4, P1-6, P1-8, P0-1.
- **App Store**: P1-7.
- **Legal**: P1-6.
- **Paiements**: P2-2, P2-11, P2-19.
- **Monitoring**: P1-12, P2-20 (superseded).
- **Analytics**: P3-14.
- **Backups**: P1-3, P3-21, R-6 (closed).
- **Recovery**: P1-3, P3-20, P3-21.
- **Feature Flags**: P2-12, part of P1-2.
- **CMS**: P3-18, part of P1-2.
- **Remote Config**: P2-9, part of P1-2.
- **Documentation**: none open — `docs/DOCUMENTATION_INDEX.md` current and this document now supersedes it for decision-making (§17).
- **Production**: P1-2, P1-3, P1-4, P1-6, P1-8, P1-12.
- **Business**: P1-6, P2-19, P3-10.
- **Qualité**: P2-10, P3-1 through P3-4.
- **UX Readiness**: P1-13, P3-18.

---

## 4. Chronological Roadmap

Sequencing consolidates `MIGRATION_APPLICATION_PLAN.md`'s dependency order, `FINAL_ROADMAP.md`'s priority order (P1→P7), and `FINAL_RECOMMENDATIONS.md`'s additions (P0/P2.5/P2.6/P5.5) — not reinvented.

### Phase A — Security migrations + Edge Function deploys (P0-1, P1-1, P2-1, P2-3, P3-15)
- **Objectif**: Close the one confirmed-live account-takeover vector and 4 related fixes.
- **Pré-requis**: Mylord's explicit per-file review (Rule 8, held throughout this entire program — no exception recommended). **Hard precondition for `20260704220000` specifically**: set `CRON_SECRET` as an Edge Function secret AND a Vault entry in production *before* applying — otherwise reminders/automation silently stop firing.
- **Risques**: P2-3's migration is the single highest-risk item in this batch if applied out of order (silent failure, not hard failure).
- **Validation**: Re-run the 6 live regression tests already written (`test/live/remediation_v1_security_fixes_test.dart`) against production after each apply.
- **Rollback**: Per-migration statements exist in `MIGRATION_APPLICATION_PLAN.md`; note `20260704190000`'s token-invalidation step is **not reversible** (zero blast radius today — 0 pending invitations in production).
- **Critères de réussite**: All 4 migrations applied; `curl` re-test of the original exploit returns blocked; CRON functions still fire on schedule.

### Phase B — Recurring backup mechanism (P1-3)
- **Objectif**: Convert the one-time backup into a scheduled job before touching anything else that adds write volume.
- **Pré-requis**: Phase A complete (security first, per this program's own risk ordering — not a hard technical dependency).
- **Risques**: None — additive, read-only cron job.
- **Validation**: First automated run produces a second backup artifact; row-count spot-check matches `pg_stat_user_tables`.
- **Rollback**: Disable the cron job; no data risk.
- **Critères de réussite**: RPO no longer growing unboundedly; a documented recurring schedule exists.

### Phase C — Deploy the 14 feature migrations, exact order (P1-2's Group 2)
- **Objectif**: Bring CMS, Remote Config, Feature Flags enterprise layer, Legal Center, Catalog, Business Observability, A/B Testing, Audit Business, Health Center dashboards, and FK indexes live.
- **Pré-requis**: Exact order (hard-failure-verified): `20260703120000→20260703130000→20260703140000→20260703150000→20260703160000→20260704100000→20260704110000→20260704120000→20260704130000→20260704140000→20260704150000→20260704160000→20260704170000→20260704180000`.
- **Risques**: `20260704120000` must precede `20260704140000`/`20260704150000`/`20260704160000`/`20260704170000` (hard failure if not: `has_system_admin()` missing); `20260704110000` must precede `20260704130000`.
- **Validation**: Health Center screen renders all 13 dashboards with real (not error) state; CMS admin screen creates content visible in `HelpCenterScreen`.
- **Rollback**: Per-migration DROP statements in `MIGRATION_APPLICATION_PLAN.md`.
- **Critères de réussite**: `information_schema.tables` shows all previously-missing tables (`cms_content`, `experiments`, `legal_documents`, `remote_config_entries`, `categories`, `service_templates`) present in production.

### Phase D — Deploy the 2 Enterprise Resilience migrations (P1-9 server half, P1-12)
- **Objectif**: Close the concurrency-bug fix and the alerting mechanism.
- **Pré-requis**: Phase C complete (`20260705110000` depends on `20260704120000`).
- **Risques**: Low — both live-tested on dr-scratch.
- **Validation**: Re-run CP0's live RPC race test against production; confirm `check-system-alerts` catches a manually-seeded incident.
- **Rollback**: DROP the new RPC/table; revert Edge Function deploys.
- **Critères de réussite**: `claim_pending_action_runs` RPC exists and is race-safe in production; `system_alerts` table populates on a real threshold breach.

### Phase E — Emergency restore-into-production rehearsal (P3-21, new per Resilience pass — P2.6)
- **Objectif**: Prove production itself, not just a scratch project, can be recovered.
- **Pré-requis**: Phase B's recurring backup in place; enough real data volume to justify the exercise (per Resilience pass's own explicit caveat — do not over-extrapolate a 10-table/82-row rehearsal).
- **Risques**: High if attempted carelessly — requires a genuine maintenance window.
- **Validation**: Full 55-table restore into a fresh, disposable project; row-for-row match.
- **Rollback**: N/A (target is disposable).
- **Critères de réussite**: A documented, timed, real restore-into-a-fresh-target playbook exists — this program has never once produced one.

### Phase F — Scalability validation + bottleneck fixes (P2-22, P2-23)
- **Objectif**: Batch/async `trg_increment_monthly_bookings`; bound the 3 unbounded Realtime queries; reach the untested 100k/20k/1M tiers.
- **Pré-requis**: None blocking — can run in parallel with Phase G.
- **Validation**: Re-run the 400k-row load test methodology at the higher tiers.

### Phase G — Android keystore + Play Store submission prep (P1-4, P1-8)
- **Objectif**: Generate the real upload keystore (Mylord-only, one-way); complete Data Safety form.
- **Pré-requis**: A custody plan for the keystore file/passwords *before* generation, per `docs/android/RELEASE_SIGNING_PROCEDURE.md`.
- **Risques**: Irreversible if lost — 2 independent durable storage locations mandatory.
- **Validation**: A real signed release APK, `apksigner verify` shows the real cert, submitted as an internal-test Play Console release.

### Phase H — Legal content + bank details (P1-6, P2-19)
- **Objectif**: Replace all placeholder content with real, reviewed copy.
- **Pré-requis**: Business/legal sign-off (not engineering).

### Phase I — iOS platform (P1-7)
- **Objectif**: Stand up iOS from zero.
- **Pré-requis**: Scoped as its own initiative — explicitly not bundled with any Android-side work in this plan.

### Phase J — Minor remaining debt (P2-8, P2-9, P2-18, P3 items)
- **Objectif**: Batch the small, cheap, never-yet-actioned items (Remote Config admin gate, missing triggers, `proxipay_sessions` unique constraint — this program's single most-repeated unfixed finding).

---

## 5. Consolidated Findings (deduplicated)

The findings below are the ones with genuine cross-pass history worth narrating individually; all others are fully specified in §2's table and not repeated here.

**Finding: `staff_profiles.invitation_token` public exposure.**
*Origine*: First found `docs/certification/PHASE_6_SECURITY_OFFENSIVE.md` (CP6, Cert v1). *Cause*: `staff_profiles_public_select` RLS policy has no role restriction (`polroles=null`), and Postgres RLS cannot hide individual columns — the policy that correctly lets clients browse the public practitioner list also exposes every column, including the one credential (`invitation_token`) that binds an account to a staff role. *Impact*: cross-tenant account takeover. *Solution*: column-limited view `v_staff_directory_public`, drop the base table's public policy, invalidate unclaimed tokens. *Ordre de correction*: first, above every other item in this program (`PHASE_11_FINAL_CERTIFICATION.md`: "ranked above every score below"). *Preuve*: live exploit before/after on `kynza-dr-scratch`, `PHASE_2_SECURITY_FIXES.md` — and a real bug caught in the fix's own first draft (`security_invoker=true` would have silently broken the practitioner picker for every client in production).

**Finding: Two concurrency bugs, found by one pass, fixed by the next.**
*Origine*: `docs/final-enterprise-validation/OFFLINE_REPORT.md` + `BACKGROUND_JOBS_REPORT.md` (found, explicitly deferred, not fixed — committed as skipped regression tests). *Cause*: both `OfflineSyncCoordinator.flush()` and `run-scheduled-actions` read a "pending work" list and process it without an atomic claim step first. *Impact*: double-applied mutation / doubled real notification send. *Solution*: `AtomicClaimService.runExclusive` (client) + `claim_pending_action_runs` RPC (server). *Ordre de correction*: fixed in `docs/enterprise-resilience/CONCURRENCY_REPORT.md` (CP0) — **do not read this as "found and fixed in the same pass"; it took two.** *Preuve*: live RPC race test on dr-scratch, both calls attempted concurrently, exactly one claim wins.

**Finding: 14→16→18→20 undeployed migrations — a growing count, not a discrepancy.**
*Origine*: Backend Completion's own close (`PHASE_11_BACKEND_COMPLETION_REPORT.md`: 13 unapplied of 72) → Certification v1 close (`PHASE_11_FINAL_CERTIFICATION.md`: 15 of 74) → Certification v2 (`CP5_OBSERVABILITY_MONITORING_GAP.md`: 16 of 75) → Remediation (`MIGRATION_APPLICATION_PLAN.md`: 18 of 77) → **today, direct re-check, 2026-07-05: 20 of 79.** *Cause*: every pass in this program kept building new schema/feature work under the same Rule 8 discipline ("no migration reaches live Supabase without Mylord's explicit approval") — the count grows because work continued, not because anything regressed or was miscounted. *Solution*: apply in the exact batched order in §7. *Preuve*: `supabase migration list --linked`, re-run as part of this consolidation.

**Finding: The Android keystore "contradiction" — resolved, not a real contradiction.**
See §6 (dedicated resolution, per this document's own mandate to treat it as the highest-priority contradiction to rule on).

**Finding: The "cold-start-offline" gap — never fixed, only ever identified.**
See §6.

---

## 6. Contradiction Rulings

### 6.1 Android release keystore — RESOLVED: both prior claims are true, about different things

**Claim A** (Enterprise Hardening pass, cited via `docs/PRODUCTION_READINESS.md` and `docs/android/RELEASE_SIGNING_PROCEDURE.md`): "Release signing ✅ resolved."
**Claim B** (Certification v2, `CP6_DEVSECOPS_INFRA.md`, `CP9_STORE_GO_NO_GO.md`): "No real Android release keystore provisioned... not Play-Store-submittable today."

**Ruling**: Both are accurate; they describe two different halves of the same mechanism, and the apparent contradiction comes from later summaries compressing "the wiring is done" into "done."

Direct evidence, re-verified as part of this consolidation (`android/key.properties`, `android/app/upload-keystore.jks` both confirmed absent, 2026-07-05):
- The **wiring** Claim A refers to is real: `android/app/build.gradle.kts` conditionally loads a real keystore from `android/key.properties` (git-ignored) and falls back to debug signing only when that file is absent. This was verified end-to-end during the Hardening pass with a disposable, non-production test keystore — a real signed release APK was built, `apksigner verify --print-certs` confirmed the test cert, and the test keystore was then deleted. Source: `docs/android/RELEASE_SIGNING_PROCEDURE.md §5`.
- The Hardening pass **deliberately did not generate the real production keystore** in that session, by explicit design, because it is a one-way secret: "generating and safeguarding the real keystore is a step only Mylord should perform... its password/keystore file must never be generated by or handed to an AI session" (`docs/android/RELEASE_SIGNING_PROCEDURE.md`, opening note).
- Certification v2 and every pass since correctly found the real key still doesn't exist, because it was never supposed to be generated by any of these passes.
- The Remediation pass independently reached the same ruling with its own direct evidence (`PHASE_4_READINESS_CLOSURES.md §1`): "not a doc inconsistency or regression — the wiring is done (Hardening pass was right), the real production keystore was never generated (Cert v2 was right)."

**Status today**: Ouvert (P1-4). Mechanism ready; real keystore generation remains Mylord's one-time action, requiring a custody plan (2 independent durable storage locations for the `.jks` + password) decided *before* generation, not after.

### 6.2 Cold-start-offline systemic bug — RESOLVED: identified, never fixed, not deployed-but-fixed

**Question posed**: is this "merely undeployed after being fixed in the Resilience pass," or "identified but never actually fixed"?

**Ruling**: **Identified but never actually fixed.** This is not a case of a fix existing somewhere undeployed — no fix was ever built.

Evidence: `docs/enterprise-resilience/BUSINESS_CONTINUITY_REPORT.md` (CP5) is the origin of this finding, and its own capability matrix is explicit: every read screen in the app (agenda, catalog/search, profile access, notification history) is a plain `FutureProvider`/`StreamProvider` with zero Hive-backed disk cache — confirmed by grepping `booking_providers.dart`, `search_providers.dart`, `client_profile_providers.dart`. The report's own framing: "a single systemic gap (no read-through cache anywhere), not four separate ones." `docs/enterprise-resilience/FINAL_RECOMMENDATIONS.md` lists the fix as **new, not-yet-started** work: `P5.5 — Disk-backed read cache for offline business continuity, informed by P0's [now P1-12's] telemetry`, with an explicit sequencing instruction: "Do not build the read-through cache (P5.5) before deploying observability [P1-12]." `docs/enterprise-resilience/EXECUTIVE_SUMMARY.md` lists it, unresolved, as reason #4 in the pass's own final "not yet" verdict.

Do not confuse this with **P1-9** (the offline-outbox/`run-scheduled-actions` **concurrency** bugs), which *were* genuinely fixed in the same Resilience pass (client fix + draft server migration) but remain undeployed. These are two separate findings from two separate reports inside the same pass; the "fixed but undeployed" status applies to P1-9, not to the cold-start-offline gap, which has never had a fix attempted.

**Status as of the Enterprise Resilience pass**: Ouvert (P1-13). **Update (Master Plan Execution
CP3, 2026-07-05)**: fixed and live-tested this pass — see §2's P1-13 row, now `Fermé (preuve)`.

### 6.3 Migration count — RESOLVED: 20 today, a genuine growth trajectory, not a miscounted discrepancy

See §5 above and §7 below for the full current classification. No contradiction — five different snapshots at five different times, all internally consistent with the codebase continuing to grow under an unbroken "never auto-deploy" discipline.

### 6.4 Scalability testing — RESOLVED: different tiers, not contradictory results

Certification v1 (`PHASE_5_SCALABILITY.md`) tested **1,000 salons / 10,000 bookings** — a first-launch-scale synthetic dataset, every query sub-5ms. Final Enterprise Validation (`SCALABILITY_REPORT.md`) tested **400,001 bookings, a real 40× increase** on the same salon/staff/service counts, and found the real bulk-write ceiling (`trg_increment_monthly_bookings`, ~150k-300k row wall). These are not competing measurements of the same thing — they are two different points on the same growth curve, run by two different passes months apart in project time, and the second pass explicitly re-ran the first pass's own queries at its new volume for direct comparison (2.17ms→6.63ms bounded; 1.39ms→63.67ms unbounded). Neither report claims to have reached the full 100k-client/20k-staff/1M-booking brief — both say so explicitly. Treat §2's P2-22/P2-23 as the current, most-advanced state of this finding.

---

## 7. Migration Deployment Plan

**Current true count, re-verified 2026-07-05**: 79 local migration files, 59 applied to production (`hhdkjfpgaklhrhfoxlhj`), **20 unapplied**. Zero classified BLOCKER.

| Group | # | Migration | Classification | Rollback | Validation step | Est. time |
|---|---|---|---|---|---|---|
| 1 — Security (apply first, priority not dependency) | 1 | `20260704190000_cp6_fix_staff_invitation_token_exposure.sql` | REVIEW | Not reversible (token-invalidation UPDATE); zero blast radius today (0 pending invitations) | Re-run original `curl` exploit, confirm blocked; confirm `practitioner_selection_screen.dart` still populates | 15 min |
| 1 | 2 | `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` | REVIEW | DROP POLICY, recreate original | Re-attempt cross-tenant PATCH, confirm 403 | 15 min |
| 1 | 3 | `20260704210000_cp11_hardening_batch.sql` | REVIEW | DROP FUNCTION/recreate, or git revert | Re-attempt anon call to `create_default_document_templates`, confirm blocked | 15 min |
| 1 | 4 | `20260704220000_cp11_cron_secret.sql` | REVIEW | git revert function code; re-run `cron.schedule` with old body | **Precondition first**: `supabase secrets set CRON_SECRET=<value>` + `SELECT vault.create_secret(...)` in production. Then apply, then confirm both cron functions still fire on next scheduled run | 30 min incl. precondition |
| 2 — Feature (exact timestamp order) | 5-18 | `20260703120000` → `20260703130000` → `20260703140000` → `20260703150000` → `20260703160000` → `20260704100000` → `20260704110000` → `20260704120000` → `20260704130000` → `20260704140000` → `20260704150000` → `20260704160000` → `20260704170000` → `20260704180000` | SAFE (all 14) | Per-migration DROP statements in `MIGRATION_APPLICATION_PLAN.md` | Health Center renders 13 real dashboards; CMS/Remote Config/Feature Flags/Legal Center/Catalog/A-B Testing/Business Observability/Audit tables all present in `information_schema.tables` | ~1 day incl. verification |
| 3 — Resilience (new, apply after Group 2) | 19 | `20260705100000_cp0_concurrency_atomic_claims.sql` | REVIEW (depends on nothing new) | DROP RPC/columns added | Re-run CP0's live race test against production | 15 min |
| 3 | 20 | `20260705110000_cp6_observability_alerting.sql` | REVIEW (depends on #12 already applied) | DROP views/table/RPC | Manually seed one threshold breach, confirm `system_alerts` row created | 30 min |

**Hard-failure dependencies** (self-correcting — apply out of order and it errors loudly): #12 (`has_system_admin()`) must precede #14/#15/#16/#17 and #20; #11 must precede #13; #17 must precede #4's dependents... none exist beyond the listed set.

**Silent-failure risk (the one item that will NOT error loudly if misordered)**: #4 (`20260704220000`) applied before its `CRON_SECRET` precondition is met will make both `kynza-booking-reminders` and `kynza-run-scheduled-actions` return 403 on every scheduled run — reminders and automation silently stop, with no error visible to any user. This is called out three times across the source reports because it is the one place this plan can fail without anyone noticing.

---

## 8. Edge Functions Plan

| Function | Action | Reasoning |
|---|---|---|
| `create_default_document_templates` RPC / `get_staff_week_rank` grant | Deploy (bundled in migration #3) | Closes P2-1 + P3-15 |
| `calculate-commission` | Modify + redeploy | Closes P2-2, code already fixed, no migration needed |
| `run-scheduled-actions` | Modify + redeploy, in strict order after migration #4's precondition | Closes P2-3 half; also needs the P1-9 concurrency fix's RPC call wired in |
| `schedule-reminders` | Modify + redeploy, same ordering constraint | Same as above |
| `check-system-alerts` | Deploy (new) | Part of P1-12; no `pg_cron` schedule exists yet — needs a production target decided first |
| `accept-invitation` | Wait | Depends on migration #1 (view repoint) landing first |
| `update-remote-config` / `rollback-remote-config` | Modify (small) | Close P2-9 — swap `role==='owner'` for `has_system_admin()` |
| Remaining 14 of 20 real production Edge Functions | Wait (no change needed) | Re-confirmed clean across CP3/CP4 of Certification v2 |

---

## 9. Security Master Plan

| Topic | State | Source |
|---|---|---|
| RBAC | 21/23 SECURITY DEFINER functions validate correctly; 2 gaps are P2-1 (fixed, undeployed) and the already-superseded `get_staff_week_rank` grant (P3-15, fixed, undeployed) | `CP2_DEEP_SECURITY.md` |
| JWT | Tampered signature, unsigned forged token, refresh-token reuse-after-grace-window all correctly blocked; refresh rotation within GoTrue's 10s grace window returns 200 by platform design, not a bug | `CP2_DEEP_SECURITY.md` |
| RLS | 55/55 tables enabled; P0-1 and P1-1 are the only 2 confirmed live gaps, both fixed-undeployed; MANAGER/SYSTEM_ADMIN isolation **tested and confirmed isolated** (Master Plan Execution CP1, 2 new QA fixtures seeded) — closed, see P2-6/P2-27 | `CP3_RLS_ADVERSARIAL_MATRIX.md`, `docs/master-plan-execution/CP1_SECURITY_CLOSURE.md` |
| Multi-tenant isolation | Holds for OWNER/CLIENT roles across 10 tables tested; STAFF has the 2 known gaps above | `CP3_RLS_ADVERSARIAL_MATRIX.md` |
| Mass assignment | P1-1, fixed-undeployed | `CP2_DEEP_SECURITY.md` |
| Privilege escalation | All tested RBAC priv-esc attempts (client→remote-config, feature-flag tamper) correctly blocked | `PHASE_6_SECURITY_OFFENSIVE.md` |
| Invitation workflow | P0-1, the program's single highest-priority open item | Multiple, see §6 |
| Commission leakage | P2-2, fixed-undeployed | `CP4_EDGE_FUNCTION_REVERIFY.md` |
| Atomic processing / concurrency | P1-9, fixed (client) / fixed-undeployed (server) | `CONCURRENCY_REPORT.md` |
| Replay protection (ProxiPay) | Verified real — server-derived nonce/timestamp, idempotency key UNIQUE-constrained, one-way state transition | `SECURITY_AUDIT_V2.md` |
| Circuit breaker | Built for the first time this program (Resilience CP2), client-side, ships next release | `CIRCUIT_BREAKER_REPORT.md` |
| Disaster recovery | One-time backup only, RPO ≈18.5h and rising, full production restore never rehearsed | `DISASTER_RECOVERY_REPORT.md` |
| Backups | Restorability proven at small scale (10 tables/82 rows) on dr-scratch only | `PHASE_0_BACKUP_CONFIRMED.md`, `DISASTER_RECOVERY_REPORT.md` |
| Monitoring / alerting | Built and proven live on dr-scratch (P1-12), zero rows exist in production because the underlying migration is undeployed | `OBSERVABILITY_ADVANCED_REPORT.md` |
| Audit logging | `activity_logs` real and append-only; `ip_address`/`device_info` inconsistently populated across functions (P2-7) | `CP1_ARCHITECTURE_REVERIFY.md` |
| Secrets | Git history clean across all 85+ commits, `.env` never committed, no hardcoded service-role keys anywhere | `CP6_DEVSECOPS_INFRA.md` |
| Key rotation | Documented for the first time this program (LEAPA/FCM/WhatsApp secrets); no rotation requires an app release | `SECURITY_AUDIT_V2.md` |
| API protection / rate limiting | 15/20 functions rate-limited; limiter fails open on its own error (P2-26); 4 functions un-rate-limited by design (cron/server-to-server) | `PHASE_3_EDGE_FUNCTION_CERTIFICATION.md`, `SECURITY_REPORT.md` |
| Supabase Security Advisor | 39 security findings at last full run (2 ERROR-level SECURITY DEFINER views = P2-4), 370 performance findings (P2-15/16/17/18/19) | `PHASE_2_DATABASE_OPTIMIZATION.md` |

---

## 10. Production Readiness Plan

- **Android**: Wiring correct, real keystore absent (P1-4). R8/shrinking verified. Runtime behavior on a real device **never verified — no Android device/emulator has existed in any pass of this entire program.**
- **iOS**: Untouched scaffold (P1-7).
- **Supabase**: 59/79 migrations live; 20 pending (§7).
- **Firebase**: Configured for Android only; Crashlytics real and wired; no `GoogleService-Info.plist` for iOS.
- **Crashlytics**: Real, called in production paths (verified in `OfflineSyncCoordinator.flush()`'s catch block).
- **FCM**: Wired; circuit-breaker-protected as of P1-10 (client-side, next release).
- **Release**: Debug-signed until P1-4 closes.
- **Monitoring/Logging/Observability**: Built, proven on staging, zero live in production until P1-2/P1-12 deploy.
- **Alerting**: Same — P1-12, staging-proven, undeployed.
- **Scaling**: Real ceiling identified (P2-22), untested beyond 400k bookings.
- **Backups/Restore**: One-time backup only (P1-3); restore-from-backup mechanism doesn't exist at all (P3-21).
- **CI/CD**: **Closed** (R-7) — genuinely executing, 5 runs, full green.
- **Release Pipeline**: `Deploy (stub)` job is a placeholder — no real deploy target/Play Store service account ever wired, never in scope of any pass.

---

## 11. DevOps Plan

- **Git**: Clean history, no secrets ever committed (verified across full history, not just recent commits).
- **Branches/Release/Hotfix**: No formal branching strategy documented in any source pass — not flagged as a defect by any pass, but also never verified; **Non validé**.
- **Rollback**: Migration-level rollback statements exist (§7); application-level rollback (rolling back a bad release) never exercised — **Non validé**.
- **Versioning**: `1.0.0+1` scheme confirmed real and consistent, `check_app_version()` RPC live.
- **Feature flags / canary / staged rollout**: Feature Flags engine exists but gates nothing live (P2-12); no canary/staged-rollout mechanism exists at the Play Console level (Data Safety/staged rollout is a Play Console setting, not a code artifact — correctly out of this codebase's scope).
- **Monitoring**: See §9/§10.

---

## 12. Scalability Plan

Two campaigns tested different tiers of the same growth curve — consolidated, not contradictory (see §6.4):

| Tier | Salons | Bookings | Source | Result |
|---|---|---|---|---|
| Launch-scale | 1,000 | 10,000 | `PHASE_5_SCALABILITY.md` (Cert v1) | All 5 hottest queries sub-5ms |
| 40× growth | 1,003 (unchanged) | 400,001 | `SCALABILITY_REPORT.md` (Final Enterprise Validation) | Bounded query 3× slower (2.17→6.63ms); unbounded query 46× slower (1.39→63.67ms); bulk-write ceiling found at ~150k-300k rows/statement |
| 100k-client/20k-staff/1M-booking brief | — | — | Never reached in either campaign | Explicitly disclosed as untested in both reports |

Capacity plan forward: batch/async `trg_increment_monthly_bookings` before any bulk-import feature ships (P2-22); bound the 3 unbounded Realtime queries before real user growth makes them expensive (P2-23); no CPU/memory/lock-contention-under-concurrent-write testing has ever been performed in this program — no load-generation tool (k6/pgbench) has ever been available in any pass's environment — **Non validé**, not "fine."

---

## 13. Final Validation Plan

Exhaustive pre-go-live checklist — every item traces to §2:

1. P0-1 through P2-3 (4 security migrations) applied to production, re-tested live.
2. 14 feature migrations applied in exact order, Health Center + CMS + Remote Config + Legal Center verified rendering real data.
3. 2 Resilience migrations applied, concurrency race test + alert-firing test re-run against production.
4. Recurring backup job live, first automated run confirmed. **Mechanism built + 2 real automated
   runs confirmed on `kynza-dr-scratch` (Master Plan Execution CP3)** — still pending deployment
   to production.
5. Real Android keystore generated, custody plan executed, signed release APK produced and `apksigner`-verified.
6. Real Privacy Policy/Terms content live, linked from app.
7. Bank transfer details real.
8. Data Safety form submitted in Play Console.
9. ~~MANAGER/SYSTEM_ADMIN QA fixtures seeded, live RLS isolation test run for both roles.~~
   **Done (Master Plan Execution CP1)** — both isolated, see P2-6/P2-27.
10. `proxipay-create-session` unique constraint added (P2-11 — this program's most-repeated open finding).
11. Full 55-table restore-into-a-fresh-project rehearsed at least once.

---

## 14. Play Store Plan

**Everything remaining**: real upload keystore (P1-4); Data Safety form (P1-8); Privacy Policy/Terms real content, linked (P1-6); resolve P0-1 (a hard blocker on any "production-ready" claim per every pass that scored Production Readiness); decide and execute a real release-build process (the `Deploy (stub)` CI job is a placeholder, never wired to a real Play Store service account in any pass). Store listing, screenshots, and feature graphic specs were never produced by any pass — **Non validé**, not started.

**Verdict carried forward unchanged**: No-Go (`CP9_STORE_GO_NO_GO.md`, reaffirmed by `CERTIFICATES/PRODUCTION_READINESS.md`).

---

## 15. App Store Plan

**Honest state**: iOS work has not started. No Apple Developer Team, no Firebase iOS config, no App Store Connect record, no TestFlight configuration, no iOS-specific entitlements file, no real device/emulator test ever performed for either platform in this entire program. `Info.plist` still missing usage descriptions and URL scheme. This is "a full second-platform launch effort, not a punch-list item" — direct quote, `CP9_STORE_GO_NO_GO.md`, and no later pass found reason to soften it.

**Verdict carried forward unchanged**: No-Go.

---

## 16. Legal Plan

- **Privacy Policy / Terms**: 100% placeholder content; infrastructure (Legal Center schema) built and pending deployment as part of the 14-migration batch. Real legal review and copy required — business-owned, not engineering.
- **Consent**: Legal Center's consent/data-deletion tables exist in the undeployed migration; RGPD audit trail (Backend Completion Phase 10) built and pending same deployment.
- **Data Safety (Play Console)**: Not started.
- **Cookies**: Not applicable — no web property audited by any source pass.
- **Licenses**: Not audited by any source pass — **Non validé**.
- **Bank info**: Literal `[À CONFIGURER]` placeholder in both `KynzaConstants` and `create-manual-invoice`; needs Mylord's real account details.

---

## 17. Documentation Plan

This document supersedes every source report listed in the table at the top of this file for **decision-making purposes only**. Those reports remain on disk as evidentiary sources — nothing is deleted or archived. `docs/DOCUMENTATION_INDEX.md` should be updated to add a final entry pointing here as the current decision-making reference; its own content otherwise remains accurate as an index of what was produced by each pass. No further audit documentation is needed before the Master Inventory (§2) is worked down — additional passes should update this document's Master Inventory directly rather than producing a 9th parallel report.

---

## 18. Final Checklist

**Security**
- ☐ P0-1 applied to production, re-tested live
- ☐ P1-1 applied to production, re-tested live
- ☐ P2-1, P2-3, P3-15 applied to production (P2-3 after its `CRON_SECRET` precondition)
- ☐ P2-2 (`calculate-commission`) redeployed
- ☐ P2-4 (2 SECURITY DEFINER views) — design decision made and drafted
- ☐ P2-21 (certificate pinning) activated with a real captured cert
- ☑ MANAGER/SYSTEM_ADMIN QA fixtures built, live isolation tested — **done, Master Plan Execution CP1**

**Infrastructure / Backend**
- ☐ 14 feature migrations applied in exact order
- ☐ 2 Resilience migrations applied
- ☐ Recurring backup job live — **mechanism built + proven on dr-scratch (CP3), not yet deployed to production**
- ☐ Full production restore rehearsed at least once — **6-table/5,087-row rehearsal done on dr-scratch (CP3), production restore still unrehearsed**
- ☐ `proxipay-create-session` unique constraint added

**Android / Play Store**
- ☐ Real upload keystore generated with a documented custody plan
- ☐ Signed release APK produced, `apksigner`-verified
- ☐ Data Safety form submitted
- ☐ Store listing, screenshots, feature graphic produced

**iOS / App Store**
- ☐ Apple Developer Team enrolled
- ☐ Firebase iOS configured
- ☐ App Store Connect record created
- ☐ Full iOS build, manual test pass completed

**Legal / Business**
- ☐ Real Privacy Policy/Terms content live
- ☐ Real bank transfer details entered
- ☐ Data Safety form (Play) reflects real data practices

**Quality**
- ☐ Repository-layer test coverage established (currently 0 files)
- ☐ P2-16/P2-17 advisor warnings reviewed per-policy (not blind rewrite)
- ☐ P2-22/P2-23 scalability bottlenecks fixed

**= 100% Production Ready**, defined precisely as: every box above checked, with the same standard of live-tested evidence this program has applied throughout — not a status update, a re-run exploit/query proving the fix holds in production itself.

---

## 19. KYNZA IS READY FOR UI/UX PREMIUM

- **Backend terminé ?** ⚠️ — Architecture 82/100, code-complete including 6 enterprise subsystems, but 21 migrations (up from 20 — see Master Plan Execution CP2) have never reached production. The features are done; production doesn't have them yet.
- **Architecture terminée ?** ✅ — `CERTIFICATES/ARCHITECTURE.md`: "Substantially unconditional, with documented non-blocking technical debt" (P3-1 through P3-4, all confirmed non-runtime-affecting).
- **Sécurité terminée ?** ❌ — A confirmed, live, unauthenticated account-takeover vector (P0-1) remains unpatched in production today, more than 24 hours (across 3 separate passes) after first being found. No security domain in this program has ever scored above "Conditional."
- **Infrastructure terminée ?** ⚠️ — CI/CD now genuinely works (closed, R-7, 7 real runs); the recurring backup mechanism is now built and proven twice on dr-scratch (Master Plan Execution CP3) — production RPO still growing by the hour until it's deployed there (P1-3, `Corrigé-non-déployé`, no longer just a one-time export with no successor mechanism).
- **Observabilité terminée ?** ❌ — Built and proven on staging (P1-12), zero of it live in production; the one function that was supposed to prove the pattern has been writing to a table that doesn't exist in production since launch.
- **Edge Functions terminées ?** ⚠️ — 20 real functions, systemic hygiene gaps (0/20 timeout, near-0/20 tracing — P3-5), 2 with confirmed live vulnerabilities (P2-2, P2-3) fixed but undeployed.
- **Supabase prêt ?** ⚠️ — 59/79 migrations live; 55 tables, RLS on all of them; 2 confirmed live gaps in that RLS (P0-1, P1-1).
- **Flutter Core prêt ?** ✅ — `flutter analyze` 0 issues, 381+/381 tests passing at every gate across every pass; architecture debt (P3-1 through P3-4) is real but non-blocking per every certificate that reviewed it.
- **Moteur Offline prêt ?** ✅ — Write-side queue works and is race-safe (P1-9 client fix); read-side's systemic cold-start-offline gap (P1-13) is now fixed and live-tested (Master Plan Execution CP3) — the one item in this section that had never even had a fix attempted now does, ships with the next app release like the other client-side fixes in this table.
- **Moteur Paiement prêt ?** ⚠️ — Replay protection verified real; commission cross-tenant disclosure fixed-but-undeployed (P2-2); `proxipay-create-session` missing a unique constraint, unaddressed across all 5 passes that flagged it (P2-11).
- **Bases techniques suffisamment solides pour démarrer l'UI Premium ?** ✅ — **Yes, directly, unambiguously** — this is the one question in this section with a clean answer, and every source pass that asked it agrees (`FINAL_REMEDIATION_REPORT.md §5`: "Yes — directly, unambiguously"; `PRODUCTION_READINESS_FINAL.md §3`: "nothing found this pass is a blocking emergency for the current, near-zero-real-traffic state of production"). The nuance: screens consuming the 14 undeployed features can be built and tested against `kynza-dr-scratch` today; they simply won't show real production data until Phase C (§4) deploys.

---

## 20. FINAL EXECUTIVE DECISION

**Question**: *À partir de quel moment puis-je arrêter définitivement les travaux Backend/Infrastructure et consacrer 100% de mon temps à l'UI/UX Premium ?*

**Is that moment now?** For starting UI/UX work — yes, today, in parallel (see §19's last line). For **stopping backend/infrastructure work entirely** — no, not yet, and every pass in this program that has been asked a version of this question has given the same answer.

**The concrete trigger condition**, not a vague timeframe: backend/infrastructure work can genuinely stop being your priority once these four items from the Master Inventory (§2) are closed — not "in progress," not "drafted," closed with production-level proof:

1. **P0-1 applied and re-verified live in production.** This is the one item every single pass in this program — certification, remediation, validation, resilience — has independently ranked above everything else. As long as it's open, no security-adjacent claim about this codebase can honestly be called "done."
2. **The 20-migration batch (§7) applied in order**, closing P1-2 — this is the direct, evidenced cause of every low Monitoring/Observability/Production-Readiness score across every scoring framework this program ever produced.
3. **A recurring backup job replacing the one-time backup (P1-3)** — the RPO is not a static number to accept; it is currently ≈18.5 hours and adding one more hour for every hour this stays open.
4. **The real Android keystore generated with a custody plan (P1-4)** — the only item in this list that is a pure Mylord decision with zero engineering dependency, and therefore the cheapest of the four to close.

Everything else in the Master Inventory (§2) — iOS, legal content, bank details, the P2/P3 debt — can genuinely run in parallel with UI/UX Premium, or after it, without contradicting any finding in this program. None of it is a "stop everything" emergency; every source pass that used that phrase used it to say the opposite (`docs/enterprise-resilience/EXECUTIVE_SUMMARY.md`: "Nothing found this pass is a 'stop everything' emergency — the fixes are real, tested, and ready. But 'ready to deploy' and 'protects production today' are not the same thing.").
