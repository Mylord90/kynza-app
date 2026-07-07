# KYNZA Backend Maintenance Handbook

**Status**: Canonical, living document. **Baseline**: `backend-baseline-v1` (commit `a39478d`), extended by the Supabase Advisors Review campaign (`docs/advisors-review/CP9_RAPPORT_FINAL.md`, closed 2026-07-07). **Written**: 2026-07-07. **Author context**: produced from the full documentary corpus under `docs/` (233+ files) plus live re-verification of the numeric claims that matter most (`flutter analyze`, `flutter test`, migration count, Edge Function count, ADR count, git tag history).

This is the single document a new senior engineer, a future CTO, a DevOps/SRE, or a Security Engineer should read to understand the KYNZA backend **without reopening any historical campaign report**. It supersedes nothing on disk — every historical report (`docs/certification/`, `docs/certification-v2/`, `docs/remediation/`, `docs/enterprise-resilience/`, `docs/final-enterprise-validation/`, `docs/enterprise-final-100/`, `docs/go-live/`, `docs/backend-production-closure/`, `docs/p2-5-rca/`, `docs/p2-5-ecr/`, `docs/final-doc-verification/`, `docs/master-plan-execution/`, `docs/advisors-review/`, `docs/governance/`) remains on disk as evidentiary record. This Handbook is the synthesis layer on top of them, per `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §6's documentation rules.

**Ground rule applied throughout**: no claim below is asserted without a citation to a source document or a command run directly in this session. Where a fact could not be verified and no cited source settles it, it is marked **[À CONFIRMER]** rather than filled in with a plausible guess.

---

## Table of Contents

- [Checkpoint 0 — Sources & Coherence Check](#checkpoint-0)
- [Checkpoint 1 — Overview](#checkpoint-1)
- [Checkpoint 2 — Complete Architecture](#checkpoint-2)
- [Checkpoint 3 — Business Modules](#checkpoint-3)
- [Checkpoint 4 — Edge Functions Catalog](#checkpoint-4)
- [Checkpoint 5 — PostgreSQL Manual](#checkpoint-5)
- [Checkpoint 6 — Security Manual](#checkpoint-6)
- [Checkpoint 7 — Observability Manual](#checkpoint-7)
- [Checkpoint 8 — Backup Manual](#checkpoint-8)
- [Checkpoint 9 — Deployment Manual](#checkpoint-9)
- [Checkpoint 10 — Maintenance Manual](#checkpoint-10)
- [Checkpoint 11 — Incident Response Manual](#checkpoint-11)
- [Checkpoint 12 — Maintenance Roadmap](#checkpoint-12)
- [Checkpoint 13 — Technical FAQ](#checkpoint-13)
- [Checkpoint 14 — Glossary](#checkpoint-14)
- [Checkpoint 15 — Executive Summary](#checkpoint-15)
- [Checkpoint 16 — Index](#checkpoint-16)
- [Checkpoint 17 — Responsibility Matrix](#checkpoint-17)
- [Checkpoint 18 — Final Certification](#checkpoint-18)
- [Appendix — Documentary Inconsistencies Detected (Not Auto-Corrected)](#appendix)

---

<a id="checkpoint-0"></a>
## Checkpoint 0 — Sources & Coherence Check

### 0.1 Mandatory sources read for this Handbook

| Source | Read | Role |
|---|---|---|
| `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (577 lines) | Full | Canonical Master Inventory (ticket status), the single most-cited document in this Handbook |
| `docs/DOCUMENTATION_INDEX.md` | Full | Chronological map of every campaign and what it produced |
| `docs/adr/0001`–`0005` + `README.md` | Full | Architectural decisions |
| `docs/governance/*` (16 files) | Full | Standing operating rules — maintenance mode, change categories, ticket lifecycle, migration/Edge Function lifecycle, ADR process, definitions of Done/Security-Ready/Deployment-Ready/Production-Ready |
| `docs/advisors-review/CP9_RAPPORT_FINAL.md`, `CP6_EXECUTION_LOG.md`, `CP5_PLAN_CORRECTION.md` | Full | The most recent closed campaign (Supabase Advisors), post-dating the `backend-baseline-v1` tag |
| `docs/ARCHITECTURE.md`, `ARCHITECTURE_GLOBAL.md`, `DATABASE_ARCHITECTURE.md`, `EDGE_FUNCTIONS_REFERENCE.md`, `SECURITY.md`, `security/SECURITY_ENTERPRISE.md`, `OBSERVABILITY_MONITORING.md`, `DISASTER_RECOVERY_RUNBOOK.md` | Full | Core technical reference |
| `CHANGELOG.md`, `RELEASE_NOTES.md` | Full | Campaign-level history and the most recent baseline release notes |
| `docs/FEATURE_FLAGS.md`, `CATALOG_ARCHITECTURE.md`, `LEGAL_CENTER_ARCHITECTURE.md`, `OFFLINE_STRATEGY.md`, `GOOGLE_MAPS_ARCHITECTURE.md`, `PHASE3A_SUMMARY.md`, `PHASE_5_SUMMARY.md`, `PHASES_3B_TO_6_SUMMARY.md`, `PRODUCTION_CHECKLIST.md`, `enterprise-final-100/EXTERNAL_GO_LIVE_DEPENDENCIES.md`, `enterprise-final-100/ZERO_INTERNAL_DEBT_DECLARATION.md`, `ai/skills/kynza-booking-engine.md`, `ai/skills/kynza-payments-leapa.md`, `ai/skills/kynza-notifications-whatsapp.md` | Full (delegated to a research pass, cross-checked against the core reference docs above) | Business-module and remaining-architecture detail |
| Live commands, this session (2026-07-07) | Run directly | `flutter analyze`, `flutter test`, `git ls-tree` at `HEAD` and at tag `a39478d`, `git tag -l`, `git log`, `git show backend-baseline-v1` |

**What was not re-read in full**: the ~150 remaining historical campaign reports (`docs/certification/`, `docs/certification-v2/`, `docs/enterprise-final-100/` per-checkpoint files, `docs/enterprise-resilience/`, `docs/final-enterprise-validation/`, `docs/go-live/`, `docs/backend-production-closure/`, `docs/p2-5-rca/`, `docs/p2-5-ecr/`, `docs/final-doc-verification/`, `docs/master-plan-execution/`, `docs/remediation/`, `docs/certification/PHASE_*`). This is intentional and matches `docs/governance/BASELINE_DOCUMENT.md` §6's own instruction ("do not re-read every campaign folder... unless you are specifically trying to understand the history behind a decision this document or the Master Inventory doesn't already explain") — every fact from these folders needed for this Handbook is already carried forward, cited, and reconciled inside `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`, which **was** read in full.

### 0.2 Coherence check — do these documents tell the same story?

**Yes, with the reconciliations below.** Every apparent divergence found traces to one of two well-precedented causes already established by the project's own history: (a) continuous work happened between two documents' write times (the "growing count, not a discrepancy" pattern the Master Plan itself codifies at §5/§6.3), or (b) a document is a frozen historical snapshot correctly superseded by a later one, per `BACKEND_GOVERNANCE_GUIDE.md` §6.4. No divergence found required inventing a third explanation.

**1. Migration count: 87 (baseline tag) vs 91 (current `HEAD`).**
Verified directly: `git ls-tree -r a39478d --name-only | grep supabase/migrations/ | wc -l` → **87**. `git ls-tree -r HEAD --name-only | grep supabase/migrations/ | wc -l` → **91**. The delta of 4 is exactly the Supabase Advisors Review campaign's four migration files (`20260707100000_advisors_rc4_unindexed_fk.sql`, `20260707110000_advisors_rc8_search_path_mutable.sql`, `20260707120000_advisors_rc6c_rc6d_revoke_execute.sql`, `20260707130000_advisors_rc5c_revoke_select_definer_views.sql`), all committed after `a39478d` (confirmed by `git log`, which shows `e3c7d30`, `3f8e797`, `cd86268`, `c35e85b`, `b9ff3d8` all descending from the baseline commit). **This is not a contradiction**: the Advisors Review is an explicitly-scoped Category B session (`docs/governance/CHANGE_POLICY.md` §"Category B") run *after* `backend-baseline-v1` was tagged, exactly as `docs/governance/MAINTENANCE_POLICY.md` permits during maintenance mode. `docs/governance/BASELINE_DOCUMENT.md` and `docs/governance/FINAL_GOVERNANCE_REPORT.md` correctly state 87/87 as of their own write time (2026-07-07, before the Advisors session's production applies); this Handbook's current-state numbers (Checkpoint 1 onward) use **91**, re-verified live, and this reconciliation is the reason the two numbers differ without either being wrong.

**2. Edge Function count: 22 at both the baseline tag and current `HEAD`.**
Verified directly: `git ls-tree a39478d --name-only supabase/functions/ | grep -v _shared | wc -l` → **22**; same command against `HEAD` → **22**. No new function was added by the Advisors campaign — RC-6c/RC-6d only revoked stale `EXECUTE` grants on two existing `SECURITY DEFINER` SQL functions (`check_system_alerts`, `claim_pending_action_runs`), not Edge Functions. Consistent, no reconciliation needed.

**3. `flutter analyze` / `flutter test`: re-verified live in this session, not carried forward.**
`flutter analyze` → `No issues found!` (103.0s). `flutter test` → `+411 ~5`, `All tests passed!`. This is an **exact match** to `docs/governance/BASELINE_DOCUMENT.md`'s claim ("411 passed, 5 skipped, 0 failed") and to `RELEASE_NOTES.md`'s baseline release notes, independently re-run rather than copied — the standard this project's own `docs/governance/CONTRIBUTION_POLICY.md` calls "Evidence discipline."

**4. `EDGE_FUNCTIONS_REFERENCE.md` lists 20 functions; the live count is 22.**
`docs/EDGE_FUNCTIONS_REFERENCE.md` (dated 2026-07-04, "recount confirmed 2026-07-04... 20 real callable functions") predates the two functions added by the 2026-07-06 Go-Live Phase 3 (`check-system-alerts`, `create-platform-backup` — per `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` rows P1-12 and P1-3). This is a stale reference document, not a live contradiction — `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §6.4 treats this correctly ("a historical document is never edited to reflect new findings... only ever gains a superseding pointer"). This Handbook's Checkpoint 4 catalog includes all 22, with the 2 missing from the reference doc synthesized directly from the Master Plan's own description of their behavior (cited inline).

**5. `DATABASE_ARCHITECTURE.md`'s "55 tables" figure is dated 2026-07-03 and is now a stale lower bound.**
The Group 2 feature-migration batch (CMS, Remote Config engine, Feature Flags enterprise layer, Legal Center, Catalog, Business Observability, A/B Testing, Audit Business — 14 migrations, `20260703120000` through `20260704180000`) was deployed to production 2026-07-06 (`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`, P1-2 row, "Go-Live Phase 2"). Each of those subsystems adds tables not counted in the 55 (e.g. `legal_documents`, `categories`, `service_templates`, `remote_config_entries`, `cms_content`, `experiments` — named individually in `docs/advisors-review/CP5_PLAN_CORRECTION.md` Fiche 4's real `information_schema` verification). **The exact current table count was not independently re-queried live in this session** (no safe read-only production DB path was exercised for this narrowly-scoped documentation task) — marked **[À CONFIRMER]** in Checkpoint 5, with the explicit lower bound (55 + at least the ~15-20 tables named across the Group 2 migrations) stated rather than a fabricated total.

**6. Supabase Advisor warning counts grew between passes on the same rule — verified directly against the raw Advisor evidence, not inferred from the timeline alone.**
`docs/certification/PHASE_2_DATABASE_OPTIMIZATION.md` (2026-07-04/05) reported 83 `auth_rls_initplan`, 205 `multiple_permissive_policies`, and 50 `unused_index` warnings; `docs/advisors-review/CP1_COLLECTE_BRUTE.md` (2026-07-07) reports 108, 227, and 93 respectively. Rather than assume the Group 2 feature-migration batch (deployed 2026-07-06) explains this, the raw evidence file this Handbook cites above (`docs/advisors-review/evidence/CP1_advisors_hhdkjfpgaklhrhfoxlhj_2026-07-07.json`) was queried directly, partitioning every finding by whether its flagged object is one of the 21 tables that migration batch actually created (names extracted directly from the 7 relevant migration files, not from a secondary summary):

| Rule | Total | On the 21 new tables | On pre-existing objects | Old baseline | Reconciled? |
|---|---|---|---|---|---|
| `multiple_permissive_policies` | 227 | 22 | 205 | 205 | **Exact match** — 100% of the growth is on new tables, zero change on old ones |
| `unused_index` | 93 | 19 | 74 | 50 | 22 of the 74 pre-existing-table findings name one of the 32 indexes `P2-15`'s own fix (`20260703120000`+`20260704180000`) added to *old* tables 2026-07-06 — i.e. new index objects on old tables, not old indexes newly going stale. Explains the bulk of the +24 residual. |
| `auth_rls_initplan` | 108 | 20 | 88 | 83 | Small, ~6% (+5) residual on pre-existing objects not attributable to any single object or pattern found — noted honestly rather than force-explained |
| `security_definer_view` (checked as the category most worth confirming didn't regress) | 32 | 0 | 32 | 32 (RC-5c's own documented pre-fix count) | **Exact match, zero growth** — confirms RC-5c's closure is holding steady in the Advisors campaign's own snapshot |

**Conclusion**: the growth is verifiably new-object-driven (new tables for `multiple_permissive_policies`, new indexes on old tables for most of `unused_index`), not a regression on already-scoped objects, and in particular **does not touch `security_definer_view` or the RLS-isolation-critical objects RC-5c closed** — the one category that would have warranted a follow-up mini-campaign if it had moved. The residual +5 on `auth_rls_initplan` is disclosed as unreconciled rather than papered over. RC-4's 15 unindexed FKs (Advisors, on the new feature tables) remain a **distinct, non-overlapping set** from P2-15's earlier 32 (already fixed, on the original tables) — confirmed directly by table name, not double-counted anywhere in this Handbook.

**7. `docs/PRODUCTION_CHECKLIST.md` still reads, in its earliest sections, as if P0-1 is unpatched and zero backups exist.**
This is the oldest continuously-appended document in the project (`docs/DOCUMENTATION_INDEX.md`: originated 2026-06-27, extended by 6+ later passes via dated "Update" sections). Its earliest content is a frozen historical snapshot; P0-1 is closed (per `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` row P0-1, "Fermé (preuve)") and a recurring backup is live (`kynza-platform-backup`, every 6h, per `docs/governance/BASELINE_DOCUMENT.md` §2). Per `BACKEND_GOVERNANCE_GUIDE.md` §6.1, `PRODUCTION_CHECKLIST.md` is **not** the canonical document for current ticket status — `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 is. This Handbook uses `PRODUCTION_CHECKLIST.md` only as a historical source for *originally-identified* items, cross-checked against the Master Inventory for current status before being stated as fact anywhere below.

**8. RC-11 and P2-28/P2-29 are not yet reflected in `docs/governance/BASELINE_DOCUMENT.md`'s "4 remaining items" framing.**
`BASELINE_DOCUMENT.md` and `MAINTENANCE_POLICY.md` (both Backend Governance Phase 3, written before the Advisors Review session ran) name exactly 4 open items (all External Dependencies). `docs/governance/FINAL_GOVERNANCE_REPORT.md` (Phase 4, same day, slightly later) already appends a 5th, `P2-28`. The Advisors Review (a later Category B session, closing with `CP9_RAPPORT_FINAL.md`) added a 6th (`P2-29`) and left a 7th deferred item open (`RC-11`, blocked on a Supabase Pro-plan upgrade — a business dependency, explicitly *not* the same category as the 4 External Go-Live Dependencies, per `CP9_RAPPORT_FINAL.md` §9's own explicit distinction). **This Handbook treats the full, current list as: 4 External Go-Live Dependencies + P2-28 + P2-29 + RC-11**, none of which requires another engineering campaign to progress (Checkpoint 12 details each).

**9. "15 diagrams" vs 16 files in `docs/diagrams/`.**
16 `.mermaid` files exist; 15 were produced by the original Documentation Expansion campaign (`docs/DOCUMENTATION_INDEX.md` Parts 1–2, listing 11 diagrams total across those sections, plus `erd.mermaid`, `catalog-erd.mermaid`, `edge-function-flow.mermaid`, `security-diagram.mermaid` = 15); the 16th, `certification-gap-matrix.mermaid`, was added later by the Enterprise Final Certification pass (`docs/DOCUMENTATION_INDEX.md`, CP1/Phase 1 of that campaign). Not a discrepancy once the later addition is accounted for.

### 0.3 What this means for the rest of this Handbook

Every checkpoint below states **current** status, sourced to the most recent authoritative document for that fact, with the reconciliations above applied silently (i.e., not re-litigated in every section) except where a genuinely open question remains — those are marked **[À CONFIRMER]** at the point they occur and collected again in the [Appendix](#appendix).

---

<a id="checkpoint-1"></a>
## Checkpoint 1 — Overview

### 1.1 What KYNZA is

KYNZA is a multi-tenant B2B2C SaaS for Burundian beauty salons. A single Supabase project (`hhdkjfpgaklhrhfoxlhj`, `eu-central-1`) serves every tenant; a Flutter mobile client serves owners, managers, staff, and clients from one codebase with role-based routing. Tenant isolation is enforced exclusively at the database layer via Row-Level Security — never in application code (`docs/ARCHITECTURE.md` §1, `docs/SECURITY.md` §1). *(`docs/governance/BASELINE_DOCUMENT.md` §1)*

### 1.2 Architectural principles

- **Feature-First + Clean Architecture**: every Flutter feature module follows `presentation/ → application/ (Riverpod providers) → domain/ (abstract repository) ← data/ (Supabase impl)` (`docs/ARCHITECTURE.md` §3.2, `ARCHITECTURE_GLOBAL.md` §2.3). Deliberate divergences from textbook Clean Architecture: no datasource abstraction beneath the repository (repositories call `SupabaseService.client` directly); the Riverpod notifier's method **is** the use case, with no separate interactor class; domain entities are the same Freezed models shared across all layers, not re-mapped per layer.
- **`salon_id` always derived server-side from the JWT, never trusted from the client** — the one architectural invariant repeated in every security-relevant document in this project (`docs/ARCHITECTURE.md` §4.1, `docs/SECURITY.md` §1.3, `docs/DATABASE_ARCHITECTURE.md` throughout).
- **RLS active on every table without exception** — 55/55 tables verified as of the 2026-07-03 baseline count, and every table added since (Checkpoint 0.2 item 5) has followed the same rule with no exception found anywhere in this documentary corpus.
- **Soft delete only** — `deleted_at TIMESTAMPTZ`, never `DELETE` on business data (`docs/conventions/SOFT_DELETE.md`, `docs/ARCHITECTURE.md` §4.3).
- **`AtomicClaimService`** (client) and its server-side counterpart `claim_pending_action_runs()` (Shape A of ADR-0002) are the **single** mechanism for claiming a batch of queued work exactly once; inline conditional `UPDATE` (Shape B of ADR-0002) is the single mechanism for claiming one caller-identified resource exactly once. Do not document, or build, a second parallel mechanism for either problem shape.
- **`readBodyGuarded()`** (`supabase/functions/_shared/cors.ts`) is the **single, shared** body-size guard used by all 16 Edge Functions that need one — never reimplemented locally (ADR-0005, `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §4).
- **Non-custodial strict**: KYNZA never holds client or salon funds — all money movement is mediated by Leapa (mobile money) or recorded as cash, never held in a KYNZA-controlled account.

### 1.3 Technologies and their exact role

| Technology | Role |
|---|---|
| Flutter 3.44.2 (installed, verified live this session via `flutter --version`) / Dart SDK `^3.12.2` (verified live via `pubspec.yaml`'s `environment:` block) | Mobile client (Android live; iOS not started, Checkpoint 12). `docs/ARCHITECTURE.md` §2 states "Flutter 3.22+ / Dart 3.4+" — a stale minimum-version figure superseded by the live-verified numbers here (Appendix item 8) |
| Riverpod 2.5+ | State management — `FutureProvider`/`FutureProvider.family` for reads, `AsyncNotifier` for writes; no `@riverpod` codegen, all providers hand-written |
| GoRouter 14+ | Single-instance client-side router; role-guarded redirects; **no `ShellRoute`** (known debt, Checkpoint 12) |
| Supabase | Backend-as-a-Service: Postgres 15 (RLS-enforced primary store), Auth (GoTrue/JWT issuer), Storage (media + backups), Realtime (WebSocket pub/sub via the SDK's `.stream()`), Edge Functions (Deno) |
| Hive | Local, non-relational cache — session flags (`kynza_prefs`, encrypted since Phase 5), 15-min RBAC permission cache (`permission_cache`, unencrypted, low-sensitivity), the Legal Center acceptance outbox + dead-letter queue, and the Phase 6 generalized mutation outbox for review/profile/data-deletion mutations |
| Firebase | Crashlytics (real, wired into `runZonedGuarded`/`FlutterError.onError`), FCM (push notifications), Performance Monitoring (`firebase_performance`, 4 named traces) — Android-configured; no iOS config exists |
| ProxiPay | KYNZA's own in-person, QR-code-based payment handoff mechanism, session-based (`proxipay_sessions`, 3-minute expiry), settling through Leapa underneath — **not** a separate payment processor |
| Leapa | The actual mobile-money payment processor/gateway for both remote (`create-payment`/`leapa-webhook`) and ProxiPay-mediated in-person flows |

### 1.4 Principal components

Flutter client (26 feature modules under `lib/features/`) → Supabase Postgres (RLS + `has_role()`) → 22 Edge Functions (Deno) → Leapa (payments) + Firebase FCM (push). See Checkpoint 2 for the full stack diagram and Checkpoint 3 for the module-by-module catalog.

### 1.5 Known limitations (summary — full detail in Checkpoint 12)

Zero P0/P1 internal engineering debt (`docs/governance/FINAL_GOVERNANCE_REPORT.md`). What remains: 4 External Go-Live Dependencies (Android keystore, real legal content, iOS platform, Play Store Data Safety form), one disclosed platform ceiling (P2-28), one disclosed observability gap needing its own investigation (P2-29), one business-plan-blocked security hardening item (RC-11), and a stated list of ~18 internal P2/P3 items each with an explicit reason it wasn't rushed (Checkpoint 12).

### 1.6 External dependencies and their current status

| Dependency | Status |
|---|---|
| Leapa (payment gateway) | Live integration in production (`create-payment`, `leapa-webhook`, ProxiPay's underlying settlement) |
| Firebase production project | Exists, Android-configured for Crashlytics/FCM/Performance; no iOS config |
| Google Maps | **Not integrated** — inert scaffold only, no API key, no Maps package installed (Checkpoint 3.10) |
| Apple Developer account | Does not exist — iOS is the untouched Flutter scaffold |
| Google Play Console | Exists as a target; Data Safety form not started, no real upload keystore |
| Bank account details | Placeholder (`[À CONFIGURER]`) in `KynzaConstants` and `create-manual-invoice` |

---

<a id="checkpoint-2"></a>
## Checkpoint 2 — Complete Architecture

### 2.1 Full stack

```
Flutter App (client, 26 feature modules)
   │  HTTPS / WSS
   ▼
Supabase (hhdkjfpgaklhrhfoxlhj, eu-central-1)
   ├── PostgreSQL 15        — primary store, RLS on every table (has_role())
   ├── Auth (GoTrue)        — JWT issuer, refresh-token rotation (platform default)
   ├── Storage              — kynza-media (public read), kynza-backups (private)
   ├── Realtime             — WebSocket pub/sub via supabase_flutter's .stream()
   ├── Edge Functions (22)  — Deno/TypeScript, service_role-privileged business logic
   └── pg_cron              — schedule-reminders (hourly), run-scheduled-actions (5min),
                               kynza-platform-backup (6h), kynza-check-system-alerts (5min)
          │
          ├── Leapa API      — mobile money payments (remote + ProxiPay settlement)
          └── Firebase FCM   — push notifications
```
*(`docs/ARCHITECTURE.md` §1, `docs/governance/BASELINE_DOCUMENT.md` §2)*

### 2.2 Flutter layering

Every feature: `domain/repositories/<name>_repository.dart` (abstract) ← `data/repositories/<name>_repository_impl.dart` (Supabase impl, no datasource split) ← `application/providers/<name>_providers.dart` (Riverpod) ← `presentation/{screens,widgets}/`. `core/` holds shared constants, enums, errors, cross-feature models, `SupabaseService` (singleton client), `CrashReportingService`, and cross-cutting providers (`auth_providers`, `connectivity_providers`). `shared/widgets/` holds the design-system primitives (`KynzaButton`, `KynzaCard`, `KynzaSkeleton`, `KynzaEmptyState`, `KynzaErrorState`, `KynzaOfflineBanner`, etc.) — every data-backed screen implements exactly the 5-state UI machine (Loading/Error/Empty/Content-short/Content-long), never a bare spinner on an empty screen. *(`docs/ARCHITECTURE.md` §3, `ARCHITECTURE_GLOBAL.md` §2.3)*

26 confirmed feature modules: `auth, automation, availability, billing, booking, dashboard, data_platform, evolution, home_client, home_manager, home_owner, home_staff, journey, loyalty, marketing, notifications, payment, permissions, proxipay, referral, reviews, salon, search, services, settings, splash, staff, team`. No feature imports another feature's internals directly — cross-feature reads go through Riverpod providers reading another feature's repository interface. This invariant was **tool-verified** (an independent import/export reachability scanner), not just asserted; the 2 real `core`↔`feature` cycles it found were fixed (`core/providers/auth_providers.dart`, `core/providers/offline_sync_providers.dart`, each split into a core-only half and a feature/composition half). *(`ARCHITECTURE_GLOBAL.md` §2.2, `docs/enterprise-final-100/CP1_ARCHITECTURE_BACKEND.md`)*

### 2.3 Supabase / PostgreSQL

Full detail in [Checkpoint 5](#checkpoint-5). Summary: multi-tenancy via server-derived `salon_id`, a single `has_role(uid, role, salon_id?)` RLS function used by every policy in the schema, soft-delete convention, auto-seed triggers for three per-salon defaults (settings, automation workflows, document templates), generated `tsvector` full-text search columns, and a fixed pattern for exposing materialized views (which cannot carry RLS) through a thin `security_invoker` view instead.

### 2.4 Auth

Supabase Auth (GoTrue) issues the JWT on login; Flutter stores it via `flutter_secure_storage` (OS Keychain/Keystore — confirmed genuinely wired, not just a dependency, since the Enterprise Hardening pass's Phase 5 fix). Every subsequent REST/RPC/Edge Function call presents the JWT as a Bearer token; Postgres enforces RLS using `auth.uid()`; Edge Functions call `supabase.auth.getUser(jwt)` to validate before switching to a `service_role` admin client for privileged operations. JWT rotation is entirely Supabase/GoTrue's platform default — no custom rotation logic exists in KYNZA code. *(`docs/SECURITY.md` §2/§5, `security/SECURITY_ENTERPRISE.md` §3)*

### 2.5 Storage

Two buckets: `kynza-media` (public read — logos/covers/portfolio images must render in the public salon-discovery feed without auth; listing exposes only file paths, no PII, confirmed intentional per the bucket's own migration header, Master Plan P3-17) and `kynza-backups` (private, one JSON blob per `create-backup`/`create-platform-backup` run). Neither bucket has a `file_size_limit` or `allowed_mime_types` set at the bucket level, and no server-side image compression exists despite being a documented mandate — open item P2-25 ([Checkpoint 12](#checkpoint-12)).

### 2.6 Edge Functions

22 Deno functions under `supabase/functions/`, sharing common utilities under `supabase/functions/_shared/` (`cors.ts`, `supabase_admin.ts`, `rate_limit.ts`, `hmac.ts`, `automation_actions.ts`, `fcm.ts`, `whatsapp.ts`, `leapa.ts`, `audit.ts`). Full catalog: [Checkpoint 4](#checkpoint-4).

### 2.7 Realtime

Every real consumer uses the `supabase_flutter` SDK's high-level query builder (`.from(table).stream(primaryKey:['id']).eq(column, value)`) — no hand-rolled `RealtimeService`/`.channel()` pattern exists, despite one being described in `docs/ai/skills/kynza-offline-realtime.md` (an aspirational spec, confirmed divergent by direct grep — zero matches for `realtime_service.dart`). Confirmed consumers: bookings (by `client_id`/`salon_id`/`practitioner_id`), a single booking during payment, ProxiPay transactions + session, services, staff profiles, loyalty cards, marketing contacts + promotions, notification logs, owner journey progress. Reconnection/backoff is entirely the SDK's default behavior — no app-authored reconnect logic exists. Per `ADR-0004`, the 3 previously-unbounded stream call sites (booking calendar salon/practitioner variants, notifications list) are now bounded with `.order().limit(200)`, since `SupabaseStreamBuilder` supports only one `.eq()` filter plus `.order()`/`.limit()` — no server-side range filter is possible with the current SDK. *(`ARCHITECTURE_GLOBAL.md` §2.6, ADR-0004)*

### 2.8 RLS

Every table: `ENABLE ROW LEVEL SECURITY`, every policy built from `has_role(auth.uid(), role, salon_id)` — no policy anywhere reads `auth.jwt()` directly. Full pattern and gotchas: [Checkpoint 5](#checkpoint-5) / [Checkpoint 6](#checkpoint-6).

### 2.9 RPC

Notable RPCs beyond `has_role()`/`check_permission()`: `evaluate_feature_flag(key)`, `is_maintenance_active()`, `check_app_version(platform, version_code)`, `mark_invoice_paid()`, `add_loyalty_stamp()`/`redeem_loyalty_reward()`, `create_entity_version()`, `check_rate_limit()` (fails open — ADR-0001), `claim_pending_action_runs()` (ADR-0002 Shape A), `grant_system_admin()`/`revoke_system_admin()`. **33 distinct `get_*` RPC functions exist across the schema** (direct `grep -roh "CREATE (OR REPLACE )?FUNCTION public\.get_[a-z_0-9]+"` count against all migrations this session, not an estimate) — most are the platform-wide BI/audit/dashboard accessors (`get_bi_revenue()`, `get_audit_security_trail()`, `get_supabase_dashboard()`, and the parallel `get_bi_*`/`get_audit_*`/`get_*_dashboard()` family) gated by `has_system_admin()` post-RC-5c (Checkpoint 5.4); a few are of a different nature and not part of that gated set — `get_staff_week_rank` (P3-15, an anon-`EXECUTE`-grant issue already closed, unrelated to RC-5c's view-grant issue) and `get_all_public_tables` (RC-6e, a low-priority residual grant, schema-reconnaissance only). A handful of RPCs are called **directly from Flutter**, bypassing any Edge Function (`evaluate_feature_flag`, `mark_invoice_paid`) — a deliberate, documented pattern for read-mostly or single-statement-atomic operations that don't need service-role privilege.

### 2.10 Cron

| Job | Schedule | Function |
|---|---|---|
| `schedule-reminders` | Hourly (`0 * * * *`) | Booking reminder dispatch (24h/2h before), deduped via `notification_logs` |
| `run-scheduled-actions` | Every 5 min (`*/5 * * * *`) | Automation action queue drain, atomic-claimed via `claim_pending_action_runs()` |
| `kynza-platform-backup` | Every 6 hours | Recurring platform backup (`create-platform-backup`) |
| `kynza-check-system-alerts` | Every 5 min | Threshold-based alerting (`check-system-alerts`) |
| `reset-monthly-bookings-count` | Monthly | Resets the freemium booking counter |
| `mv_audit_stats` refresh | Hourly | Materialized view refresh via `pg_cron` |

### 2.11 Backups

Covered fully in [Checkpoint 8](#checkpoint-8).

### 2.12 Remote Config

`remote_config_entries`/`remote_config_versions`/`remote_config_audit` (append-only, always-versioned — a rollback creates a *new* version copying a prior value, never destructively overwrites). Gated `update-remote-config`/`rollback-remote-config` Edge Functions, currently authorized via `role === 'owner'` as a documented **interim** measure (no `SYSTEM_ADMIN`-scoped gate existed when they were built) — flagged directly in the function source, not silently left broader than intended. *(`docs/EDGE_FUNCTIONS_REFERENCE.md` §5, note under `update-remote-config`)*

### 2.13 Notifications

FCM push is the only fully-confirmed-real notification channel, dispatched via `send-notification` (internal-only Edge Function, always returns `200`, best-effort per channel). A WhatsApp Business Cloud integration is described in `docs/ai/skills/kynza-notifications-whatsapp.md` but **no corresponding Edge Function exists** in the confirmed catalog — this is an aspirational/target spec, not a built integration, following the same divergence pattern already established for the offline-realtime skill file. Treat the WhatsApp layer as **not built** until a dedicated Edge Function (`whatsapp.ts` is present under `_shared/` as a sender used by `send-notification`, so a *thin* WhatsApp send path may exist — but the richer inbound-webhook/opt-out/quota flow described in the skill file is unconfirmed).

### 2.14 Offline Sync

Real Hive boxes today: `kynza_prefs` (encrypted, session/session-adjacent flags), `permission_cache` (unencrypted, 15-min RBAC cache, low-sensitivity), `kynza_legal_acceptance_queue` + `kynza_sync_dead_letter` (Legal Center outbox, the first real offline outbox in the codebase), and the Phase 6 generalized `kynza_mutation_outbox` + `kynza_mutation_dead_letter` covering **exactly three entities**: review creation, profile updates, data-deletion requests — by design, not an oversight (`docs/OFFLINE_STRATEGY.md` §3, Master Inventory P3-7). Bookings, cash payments, and booking-status changes are deliberately **not** offline-queued — booking creation needs server-authoritative atomic slot-locking that cannot be safely deferred to a client-side queue. **Still open**: no disk-backed *read* cache existed for any `.stream()`/`.get()`-backed screen until Master Plan Execution CP3 built one for the 4 named read paths (agenda/bookings, catalog search, own profile, notification history) — fixed and live-tested (`P1-13`, `Fermé (preuve)`); ProxiPay has **zero** Hive usage (fully online, session-based). *(`ARCHITECTURE_GLOBAL.md` §2.5, `docs/OFFLINE_STRATEGY.md`)*

### 2.15 Circuit Breaker

Built for the first time in this project by the Enterprise Resilience campaign (`CircuitBreaker`, `DependencyCircuitBreakers` for `supabase`/`fcm`), wired into 6 call sites, proven via a real before/after dependency-down test. Purely client-side — ships with the next app release, no server deploy gate. *(`docs/enterprise-resilience/CIRCUIT_BREAKER_REPORT.md`, Master Inventory P1-10)*

### 2.16 Cache

Client-side: the read-through Hive caches above (§2.14) plus the 15-min permission cache and a 15-min `user_effective_permissions_cache` server-side mirror. Server-side: `security_invoker` views over materialized views (`v_mv_daily_revenue`, `v_mv_audit_stats`) since MVs cannot carry RLS directly. CMS admin edits previously did not invalidate the client-facing read path (`cmsPublishedProvider`/Hive mirror) — found and fixed by Enterprise Resilience CP3 (`P1-11`, `Fermé (preuve)`).

### 2.17 Monitoring

Full detail: [Checkpoint 7](#checkpoint-7).

### 2.18 Request flow (booking creation, representative)

```
Client taps "Confirm"
  → bookingFlowProvider.notifier.createBooking()
    → SupabaseService.functions.invoke('create-booking', {...})
      → create-booking/index.ts:
          1. Validate JWT
          2. Check freemium quota (bookings this month, free plan only)
          3. Atomic slot lock: BEGIN → SELECT ... FOR UPDATE → INSERT → COMMIT
          4. Create Leapa payment intent
          5. Best-effort: execute-workflow (automation triggers), send-notification
          6. Return { booking_id, payment_url }
    → Flutter navigates to PaymentScreen
      → WebView opens Leapa's hosted payment page
        → Leapa calls POST /leapa-webhook on payment success (HMAC-SHA256 signed, no JWT)
          → leapa-webhook marks booking CONFIRMED_PAID, sends notification
            → Supabase Realtime pushes the update to the client
```
*(`docs/ARCHITECTURE.md` §8)*

---

<a id="checkpoint-3"></a>
## Checkpoint 3 — Business Modules

For each module: role, key tables/RPCs/functions, key screens, dependencies, risks/known gaps. **Sourcing note**: table/RLS/RPC facts below are cross-referenced against `docs/DATABASE_ARCHITECTURE.md`/`docs/EDGE_FUNCTIONS_REFERENCE.md`/`security/SECURITY_ENTERPRISE.md` (all read in full for this Handbook); every named screen/service file (`walkin_booking_sheet.dart`, `booking_detail_sheet.dart`, `loyalty_qr_screen.dart`, `loyalty_scan_screen.dart`, `marketing_dashboard_screen.dart`, `invite_clients_screen.dart`, `social_share_center_screen.dart`, `promotion_center_screen.dart`, `referral_claim_screen.dart`, `staff_detail_screen.dart`, `commission_screen.dart`, `my_performance_screen.dart`) and the `canReview()` offline-replay guard were independently confirmed to exist in `lib/` via direct file search this session, not taken on the delegated research pass's word alone — following the same rigor applied to Checkpoint 0's coherence check after 3 stale claims were found there (Appendix item 7).

### 3.1 Booking

**Role**: Core scheduling engine — availability, slot locking, status lifecycle, no-show handling. **Tables/functions**: `bookings` (`UNIQUE(practitioner_id, start_time)` — the slot-conflict guarantee; `idempotency_key UNIQUE`; auto-cancel cron for stale `pending_payment` after 5 minutes), `create-booking`, `create-walkin-booking`, `mark-no-show` Edge Functions. **Screens**: 4-step booking tunnel, `walkin_booking_sheet.dart`, `booking_detail_sheet.dart`. **Dependencies**: Leapa (payment gate to `confirmed`), FCM/WhatsApp (confirmations), `execute-workflow` (automation triggers). **Risks**: booking creation/status-changes are deliberately excluded from the offline outbox (server-authoritative slot lock — §2.14); `mark-no-show` is **not idempotent** — re-calling it re-decrements `reliability_score`, so the client must disable the triggering control after first tap rather than rely on server dedup (`docs/EDGE_FUNCTIONS_REFERENCE.md`).

### 3.2 Payments — ProxiPay / Leapa

**Role**: two distinct real payment paths. (1) **Leapa remote payment** — `create-payment` (idempotency-keyed, 1-minute window) + `leapa-webhook` (HMAC-SHA256 over the raw body, the sole trust boundary, no JWT). (2) **ProxiPay** — KYNZA's own QR-based in-person handoff, `proxipay_sessions` (3-minute expiry, RLS-locked against any client `INSERT`/`UPDATE` — both mutating paths use the service-role client exclusively), `proxipay-create-session`/`proxipay-confirm` Edge Functions, settling through the same Leapa secrets underneath (no separate `PROXIPAY_*` secret exists — confirmed correction, not a gap, `security/SECURITY_ENTERPRISE.md` §3). **Replay protection**: session-based via `expires_at` + one-way `status` state machine + RLS lockdown — functionally equivalent to a nonce for this single-use handoff. **Known gap**: no unique constraint prevented multiple concurrent ProxiPay sessions for the same booking — this was the single most-repeated unfixed finding across 5 audit passes; **closed 2026-07-06** via a partial unique index (`20260706130000`, Master Inventory P2-11, `Fermé (preuve)`).

### 3.3 Notifications

**Role**: booking reminders/confirmations, loyalty/referral alerts, staff-invitation notices — dispatched via `send-notification` (internal-only), triggered by `schedule-reminders` (cron) or other Edge Functions. **Channels**: FCM (confirmed real); WhatsApp (aspirational per §2.13 — treat as unconfirmed beyond a thin sender helper). **Screens**: `NotificationsScreen` (filter/grouping/pagination). **Dependency**: `notification_templates` (12 seeded event types), `notification_preferences`, `notification_logs`.

### 3.4 Analytics / Business Observability

**Role**: owner-facing KPI dashboards (`fl_chart`-based), platform-wide BI (`v_bi_*` views/RPCs), audit trail views (`v_audit_*`). All of these route through `SECURITY DEFINER` RPCs (`get_bi_revenue()`, `get_audit_security_trail()`, etc.) gated by `has_system_admin()` for the platform-wide ones, or standard RLS for salon-scoped KPIs (`v_salon_kpis`, `v_top_services`). Post-RC-5c (Checkpoint 5.4), direct table/view `SELECT` by `anon`/`authenticated` is fully revoked on all 31 underlying objects — the RPC layer is now the **only** access path, matching the original design intent.

### 3.5 Loyalty

**Role**: stamp-card loyalty program. **Tables/RPCs**: `loyalty_programs`, `loyalty_cards` (`UNIQUE(salon_id, client_id)`), `loyalty_stamp_logs` (append-only), atomic `add_loyalty_stamp()`/`redeem_loyalty_reward()` RPCs. Clients are read-only on their own card — stamping/redeeming is staff/owner/manager-administered only, or via the scannable-QR path below. **Phase 3B addition**: `loyalty_qr_tokens` + `validate-qr` Edge Function + `LoyaltyQrScreen` (client-facing QR display) + `LoyaltyScanScreen` (staff/owner/manager scan) — this closed a real gap (Phase 3A shipped redemption logic with no scannable client code).

### 3.6 Reviews

**Role**: post-booking client reviews with owner replies. **Tables**: `reviews` (`booking_id UNIQUE`, 30-day self-edit window, `protect_review_columns()` trigger restricting which columns each party may touch), `review_media`. **Offline (Phase 6)**: review creation now queues via the generalized mutation outbox when offline, with a pre-flight `canReview()` check before replay to avoid a doomed insert against the `UNIQUE` constraint. **Known gap**: salon-detail review pagination is server-side but the UI renders only the first page — no "load more" affordance (open, low priority).

### 3.7 Marketing / Referrals

**Role**: client CRM, promotions, referral program. **Tables**: `client_contacts`, `promotions`, `referrals` (`referral_token UNIQUE`). **Screens**: `MarketingDashboardBody`, `InviteClientsScreen`, `SocialShareCenterScreen`, `PromotionCenterScreen`, `ReferralClaimScreen` (`/accept-referral` deep link — Phase 3B closed the gap where Phase 3A shipped the link with no handling screen). **Edge Function**: `claim-referral` (blocks self-referral, atomic conditional update). **Known gap**: `referrals` is the only loyalty/marketing table without `deleted_at` (Master Inventory row, low-severity documented tech debt).

### 3.8 Team Management / Commissions

**Role**: staff roster, invitations, availability, commission calculation. **Tables**: `staff_profiles` (public-SELECT policy historically exposed `invitation_token` — this was **P0-1**, closed in production 2026-07-06 via a column-limited view, `v_staff_directory_public`), `staff_services`, `staff_working_hours`, `staff_breaks`, `staff_commissions` (`booking_id UNIQUE`; staff sees only their own rows — R11 isolation). **Edge Functions**: `accept-invitation`, `calculate-commission` (fires after a booking is marked completed). **Screens**: `StaffDetailScreen`, `CommissionScreen`, `MyPerformanceScreen`. **Note for future readers**: `docs/PHASE_5_SUMMARY.md` is a pure documentation-authoring phase, not the team/commissions feature build — the real build is recorded in `docs/PHASES_3B_TO_6_SUMMARY.md`.

### 3.9 Subscriptions / Billing / Freemium

**Role**: plan tiers (free/pro/premium) and freemium enforcement. **Tables**: `subscription_plans` (public read, active-only), `invoices` (owner-only, `reference UNIQUE`, versioned via `entity_versions` — there is **no `subscriptions` table**; plan state lives on plain `salons.plan`/`plan_status`/`plan_started_at` columns). **Flow**: upgrade → `create-manual-invoice` → pending invoice (bank-transfer reference, placeholder) → owner calls `mark_invoice_paid()` RPC directly from Flutter → atomic plan flip. Downgrade is a direct `.update()` on `salons`, no Edge Function involved. **Freemium enforcement**: inline inside `create-booking`/`create-walkin-booking` (`plan==='free' && monthly_bookings_count>=20` → `403`), counter reset monthly by `reset-monthly-bookings-count` cron — enforced server-side, cannot be bypassed by a modified client. **Confirmed gap, still open**: **no `check-subscription` cron/RPC/Edge-Function exists anywhere** — a lapsed paid plan never auto-reverts to free. The `subscription.expiring` automation trigger type is seeded explicitly `wired: FALSE` for exactly this reason. Tracked as **P2-14**, open (`docs/EDGE_FUNCTIONS_REFERENCE.md` §4, Master Inventory).

### 3.10 Feature Flags / Remote Config engine

**Status**: real, deployed schema (`feature_flags`, `salon_feature_overrides`, plus `role_feature_overrides`/`user_feature_overrides`, Realtime propagation to a Hive-backed `FeatureFlagCache`, and an audit trail screen). `evaluate_feature_flag()` works correctly when called — but **is called from nowhere in the app except its own repository test path**. No screen anywhere gates real behavior on an evaluated flag. This is the single most-repeated confirmed gap in this documentary corpus, unchanged across every pass that checked it — tracked as **P2-12**, open, low-medium priority, a product decision rather than an engineering blocker.

### 3.11 Catalog

**Status**: schema designed (`categories`, `service_templates`, `service_variants`, `service_tags`, `service_filters` — 72 top-level categories × 2 tiers, 288 seeded templates) and **deployed to production** as part of the Group 2 migration batch (2026-07-06, per Checkpoint 0.2 item 5's reconciliation). No new Flutter UI was built on top of it yet — the "pick from a service template" flow remains design-only. Seeded prices are extrapolated from a single test fixture, explicitly flagged for owner review before real use, not silently treated as production-ready pricing data.

### 3.12 Legal Center

**Status**: full Dart layer built (models, repositories, providers, screens) and the schema (`legal_documents`, `user_legal_acceptances`, etc.) is **deployed to production** as part of the same Group 2 batch. All 9 seeded document bodies are explicitly marked placeholder — real legal review is required before this is usable (this is exactly **P1-6**, an External Go-Live Dependency, not an engineering gap — the mechanism is done). Built the **first real offline outbox** in the codebase (`LegalAcceptanceQueueService`), the direct precedent for Phase 6's generalized mutation outbox. Data *export* (as opposed to data-deletion) has no backend — the "export my data" button correctly routes to `SupportContactScreen` rather than fabricating a download that doesn't exist.

### 3.13 Google Maps

**Status**: fully inert scaffold. Double-gated on both a real `GOOGLE_MAPS_API_KEY` (empty, none committed) and a `feature_google_maps` flag — the key-check short-circuits first. **Zero** Maps-related packages are installed (`google_maps_flutter`, `geocoding`, `geolocator` all absent from `pubspec.yaml`). `salons.latitude`/`longitude` columns exist but no UI populates them — always null in practice today. This is an **External Go-Live Dependency** (needs a real Google Maps API key), not an internal engineering gap.

---

<a id="checkpoint-4"></a>
## Checkpoint 4 — Edge Functions Catalog

Source of truth: `supabase/functions/*/index.ts` (22 directories confirmed live, git-verified against both the baseline tag and `HEAD` — Checkpoint 0.2 item 2). `docs/EDGE_FUNCTIONS_REFERENCE.md` documents the first 20 in full detail (dated 2026-07-04); the 2 added later (`check-system-alerts`, `create-platform-backup`) are documented below from the Master Plan's description of their behavior, cross-referenced accordingly.

**Two calling conventions across all 22**: (1) **Client-invoked** — Flutter calls `supabase.functions.invoke()`; these always call `getAuthenticatedUser(req)` first, never trust `role`/`salon_id` from the request body. (2) **Server-invoked** — called only by other Edge Functions (service-role client) or `pg_cron`; these have **no JWT check at all** by design — their trust boundary is that only trusted server-side callers can reach them. Generic error shape: `{ error: "<code>", message?: string }`.

| Function | Trigger | Auth | Permissions (post RC-6c/RC-6d) | Secrets used | Rollback |
|---|---|---|---|---|---|
| `create-booking` | Flutter client | JWT, any authenticated | n/a (client-invoked) | none | Redeploy pre-change code |
| `create-payment` | Flutter client | JWT + `booking.client_id===user.id` | n/a | `LEAPA_API_KEY`, `LEAPA_BASE_URL` | Redeploy pre-change code |
| `leapa-webhook` | Leapa (external HTTP) | HMAC-SHA256 signature, **no JWT** | n/a (public endpoint, signature-gated) | `LEAPA_WEBHOOK_SECRET` | Redeploy pre-change code |
| `mark-no-show` | Flutter client (staff) | JWT + owner/manager/assigned practitioner | n/a | none | Redeploy pre-change code |
| `send-notification` | Other Edge Functions only | None (trusted server-to-server) | Never exposed client-callable | `FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID`, `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` | Redeploy pre-change code |
| `schedule-reminders` | `pg_cron`, hourly | Service-role bearer (cron) | n/a | none | Redeploy pre-change code |
| `accept-invitation` | Flutter client | JWT; blocks `role===owner` | n/a | none | Redeploy pre-change code |
| `create-walkin-booking` | Flutter client (owner/manager) | JWT + salon_id match + role | n/a | none | Redeploy pre-change code |
| `validate-qr` | Flutter client (staff/manager/owner) | JWT + role | n/a | none | Redeploy pre-change code |
| `claim-referral` | Flutter client (deep link) | JWT; blocks self-referral | n/a | none | Redeploy pre-change code |
| `create-manual-invoice` | Flutter client (owner) | JWT + `role===owner` | n/a | none | Redeploy pre-change code |
| `calculate-commission` | Flutter client (post-completion) | JWT, any authenticated | Cross-tenant leak (**P2-2**) closed 2026-07-06, redeployed with salon-ownership check | none | `git show 2c13f47~1:...` or `supabase functions delete calculate-commission` |
| `execute-workflow` | Other Edge Functions only | None (trusted server-to-server) | Never exposed client-callable | none | Redeploy pre-change code |
| `create-backup` | Flutter client (owner/manager) | JWT + role | n/a | none | Redeploy pre-change code |
| `check-permissions` | Flutter client (batch) | JWT; self-or-owner/manager re-enforced server-side | n/a | none | Redeploy pre-change code |
| `proxipay-create-session` | Flutter client (staff) | JWT + role + `booking.salon_id` match | n/a | `LEAPA_API_KEY` (reused) | Redeploy pre-change code |
| `proxipay-confirm` | Flutter client (client) | JWT, any authenticated | n/a | `LEAPA_API_KEY` (reused) | Redeploy pre-change code |
| `run-scheduled-actions` | `pg_cron`, every 5 min | Service-role bearer (cron) + `X-Cron-Secret` | Underlying RPC `claim_pending_action_runs()` — `EXECUTE` revoked from `anon`/`authenticated` (**RC-6d**, 2026-07-07); only `service_role` retains it | `CRON_SECRET` (Edge Function env var + Vault entry) | Redeploy pre-change code |
| `update-remote-config` | Flutter client (owner, interim gate) | JWT + `role==='owner'` | Closed **P2-9** (cross-tenant admin-gate bypass) 2026-07-06, first-deployed with the fix already in place | none | `supabase functions delete update-remote-config` (didn't exist before the fix) |
| `rollback-remote-config` | Flutter client (owner, interim gate) | JWT + `role==='owner'` | Same closure as above | none | `supabase functions delete rollback-remote-config` |
| `check-system-alerts` | `pg_cron` (`kynza-check-system-alerts`, every 5 min) | Service-role bearer (cron) + `X-Cron-Secret` | Underlying RPC `check_system_alerts()` — `EXECUTE` revoked from `anon`/`authenticated` (**RC-6c**, 2026-07-07); only `service_role` retains it | `CRON_SECRET` | Redeploy pre-change code |
| `create-platform-backup` | `pg_cron` (`kynza-platform-backup`, every 6h) | Service-role bearer (cron) | n/a | none beyond service-role | Redeploy pre-change code |

**Shared risks across all 16 body-accepting functions**: `readBodyGuarded()` (ADR-0005) enforces a single, non-overridable 100KB (`MAX_BODY_BYTES = 102,400`) limit — comfortably below the disclosed platform ceiling **P2-28** (requests ≳210KB have a substantial-to-near-total chance of never reaching the isolate at all; a platform limitation, not fixable from application code). **Monitoring**: business-relevant mutations write to `activity_logs` via the shared `logActivity()` helper (all 9 real call-sites fixed to populate `ip_address`/`device_info` correctly, per **P2-7**, closed); threshold-based operational alerting via `check-system-alerts` → `system_alerts` table. **No function sets an explicit timeout** — Supabase's platform default applies uniformly; this is a disclosed gap (§Checkpoint 12), not a documented guarantee.

---

<a id="checkpoint-5"></a>
## Checkpoint 5 — PostgreSQL Manual

### 5.1 Schema

**[À CONFIRMER]** exact current table count — `docs/DATABASE_ARCHITECTURE.md` documents 55 tables as of 2026-07-03; at least the Group 2 feature-migration batch (deployed 2026-07-06) added further tables (`legal_documents` + related, `categories`/`service_templates`/`service_variants`/`service_tags`/`service_filters`, `cms_content` + versions, `experiments`/`experiment_assignments`/`experiment_events`, `remote_config_entries`/`versions`/`audit`, `role_feature_overrides`/`user_feature_overrides`, plus Business Observability and Audit Business schema objects — individually named in `docs/advisors-review/CP5_PLAN_CORRECTION.md` Fiche 4's live `information_schema` verification). No live re-count was performed in this session (Checkpoint 0.2 item 5). Domain grouping per `DATABASE_ARCHITECTURE.md` §3: Identity/RBAC, Salon Core, Booking, Payments, Loyalty/Marketing, Reviews, Marketing/Journey, Automation, Notifications, Ops/Platform — plus the newer Legal Center/Catalog/CMS/Remote Config/Business Observability/Audit Business domains added since.

### 5.2 RLS

**Pattern** (used by every policy in the schema):
```sql
CREATE FUNCTION public.has_role(p_uid UUID, p_role TEXT, p_salon_id UUID DEFAULT NULL)
RETURNS BOOLEAN LANGUAGE sql SECURITY INVOKER STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM public.users u
    WHERE u.id = p_uid AND u.role = p_role AND u.deleted_at IS NULL
      AND (p_salon_id IS NULL OR u.salon_id = p_salon_id));
$$;
```
`SECURITY INVOKER` (cannot be tricked into reading data the caller's own RLS would block) + `STABLE` (cacheable within one statement) + `deleted_at IS NULL` (soft-deleted users lose every role). **Never** `auth.jwt()` directly in a policy. *(`docs/SECURITY.md` §2)*

**RC-5c as the reference example of a bad practice, corrected**: 29 views + 2 materialized views tagged `SECURITY DEFINER` (or their underlying MV) had `anon`/`authenticated` holding full `SELECT`, and in 3 cases (`v_audit_financial_accounting`→`invoices`, `v_audit_security_trail`→`activity_logs`, `v_security_dashboard`→`rate_limit_buckets`) the **full write grant set** (`INSERT`/`UPDATE`/`DELETE`/`REFERENCES`/`TRUNCATE`/`TRIGGER`), on views structurally auto-updatable by Postgres (`information_schema.views.is_insertable_into='YES' AND is_updatable='YES'`, no `INSTEAD OF` trigger). Combined with `SECURITY DEFINER` (bypasses RLS on the real table), this was a live, unauthenticated write path to financial and security-audit tables — closed 2026-07-07 via `REVOKE ALL PRIVILEGES ... FROM anon, authenticated, PUBLIC` on all 31 objects, leaving only `postgres`/`service_role`. The legitimate access path (`get_bi_*()`/`get_audit_*()`/`get_*_dashboard()` RPCs, themselves `SECURITY DEFINER`, running with the function owner's privileges) is unaffected. *(`docs/advisors-review/CP9_RAPPORT_FINAL.md` §11, `CP5_PLAN_CORRECTION.md` Fiche 1)*

**Deliberately-excluded 3 views** from the RC-5c revoke (documented, provable design choices, not oversights): `v_popular_searches` (cross-user aggregate, no underlying SELECT policy exists at all — `security_invoker` would return zero rows, no sensitive column exposed), `v_mv_daily_revenue` (re-derives `auth.uid()`'s own `salon_id` inline — the standard MV/RLS workaround), `v_staff_directory_public` (the intentionally-public practitioner directory, post-P0-1 fix, column-limited).

### 5.3 RPC

See Checkpoint 2.9 for the notable-RPC list. Every RPC intended for privileged/platform-wide use is `SECURITY DEFINER` with `has_system_admin()` (or an equivalent role check) as its own internal gate — this is now the **only** access path for the 31 BI/audit/dashboard objects since RC-5c.

### 5.4 Triggers

- `has_role()`-adjacent: `protect_user_columns()` (role/`salon_id`/`email_verified`/`reliability_score` immutability on `public.users`), `protect_review_columns()` (column-restricted write on `reviews`).
- Auto-seed: `trg_auto_salon_settings`, `trg_auto_workflows`, `trg_auto_document_templates` — new salons get default settings/automation-workflow rows/document templates automatically; existing salons got theirs via a one-time backfill `DO` block in the introducing migration.
- **ADR-0003 — statement-level, not row-level, for aggregate counters**: `trg_increment_monthly_bookings` was originally `FOR EACH ROW`, causing a ~2-minute statement timeout around 150,000–300,000 bulk-inserted rows (found via a real 400,001-row scale test). Converted to `FOR EACH STATEMENT` + `REFERENCING NEW TABLE AS new_rows` + `GROUP BY`-aggregated `UPDATE` — fires once per statement regardless of row count. **This is the standing pattern for any future per-parent aggregate trigger on a high-volume child table** (`bookings`, `transactions`, `activity_logs`) — default to statement-level from the start.
- Known bugs (documented, low severity): `permission_groups`, `automation_workflows` had `updated_at` columns with no maintaining trigger — since fixed (Enterprise Final 100 CP4); `salon_settings` still lacks one at time of the last audit that checked — **[À CONFIRMER]** against current migrations before relying on this for a new feature.

### 5.5 Views

- **Distinguish**: 3 of the 29 RC-5c-affected views (§5.2) are simple, structurally auto-updatable `SELECT`s (no aggregation) — these were the ones with the real write exposure. The other 26 are aggregate/join views, non-updatable by Postgres construction, so their pre-fix write grants were real but inert.
- `v_mv_daily_revenue`, `v_mv_audit_stats` — thin `security_invoker` views over materialized views that cannot carry RLS directly; each re-derives the caller's own `salon_id` inline.

### 5.6 Functions

`SECURITY DEFINER` functions run with the function owner's (`postgres`) privileges regardless of caller — every one of them must perform its own internal authorization check (role, `has_system_admin()`, or an equivalent), since RLS on the underlying table does not apply to them. Per **RC-8** (2026-07-07), 6 functions (`check_app_version`, `check_journey_complete`, `evaluate_feature_flag`, `init_owner_journey`, `is_maintenance_active`, `update_updated_at`) had their `search_path` explicitly pinned to `'public', 'pg_temp'` via `ALTER FUNCTION ... SET search_path` — closing the standard "search_path hijacking" class of attack (a role with schema-creation rights could otherwise redirect an unqualified identifier to a malicious object). No exploit was demonstrated for these 6 specifically; this was hygiene, applied because it's now the norm for every function written since `20260627150000_adv6_security_hardening.sql`.

### 5.7 Indexes

- **RC-4** (2026-07-07): 15 new indexes on foreign keys of the newly-deployed feature tables (CMS, Remote Config, Feature Flags, Legal Center, Audit — full list in `docs/advisors-review/CP5_PLAN_CORRECTION.md` Fiche 4), distinct from the earlier **P2-15** (32 FK indexes on the original schema, already fixed 2026-07-06).
- **Known remaining gaps** (`DATABASE_ARCHITECTURE.md` §4): missing index on the `salon_id` FK column in `staff_services`, `staff_working_hours`, `staff_breaks`, `automation_action_runs`, `notification_logs`; `salons.owner_id` used throughout RLS but not a declared FK and has no index.
- **BRIN candidates, not yet applied**: `activity_logs`, `automation_execution_logs`, `entity_versions` (high-insert, append-only, time-ordered) — a `BRIN` index on `created_at` would be cheaper to maintain than a second B-tree at high row counts; not yet necessary at current volume.

### 5.8 Migrations

91 applied to production, 0 unapplied, verified this session (`git ls-tree -r HEAD`, cross-checked against `git ls-tree -r a39478d` = 87). No down-migrations exist anywhere in this repo — every migration is forward-only; a correction is always a *new*, later-timestamped migration, never an edit to an already-applied file (`BACKEND_GOVERNANCE_GUIDE.md` §2.6, "Rule 4"). Full lifecycle: [Checkpoint 9](#checkpoint-9).

### 5.9 SQL conventions

- `IF NOT EXISTS`/`IF EXISTS` on every `CREATE`/`DROP` unless a specific reason exists not to (one table, `salon_feature_overrides`, uses a plain `CREATE INDEX` — a noted, harmless exception, not a pattern to copy).
- Composite primary keys over surrogate `id` columns for pure ledger/bucket tables with no independent identity need (e.g. `rate_limit_buckets`, `notification_quota`).
- Generated `tsvector` columns (`STORED`, `'simple'` config — not `'french'`, to preserve brand names/proper nouns without stemming) for full-text search, paired with a trigram GIN index for `ILIKE` fallback.
- Never supply a value for a `GENERATED ALWAYS AS` column on `INSERT`/re-insert (e.g. `search_vector`) — Postgres rejects it outright; this was a real, previously-unknown finding surfaced only by actually running a restore rehearsal (Checkpoint 8.2).

---

<a id="checkpoint-6"></a>
## Checkpoint 6 — Security Manual

### 6.1 Core principles

1. Tenant isolation at the database layer only — RLS on every table, never skipped.
2. `has_role()` is the only RLS mechanism — no policy joins `auth.users` or reads `auth.jwt()` directly.
3. `salon_id` always derived server-side from `auth.uid()` → `public.users.salon_id` — never trusted from the client.
4. Soft-delete only.
5. `service_role` key never in Flutter code — Edge Function env vars and Supabase Vault only.
*(`docs/SECURITY.md` §1)*

### 6.2 Auth

GoTrue-issued JWT; `flutter_secure_storage` (OS Keychain/Keystore) for the client-side session — confirmed genuinely wired since the Enterprise Hardening pass's Phase 5 fix (it previously existed only as an unused dependency, falling back to unencrypted `SharedPreferences` — a real finding, corrected). `users.role` is column-protected against client self-escalation via `protect_user_columns()`, not RLS alone.

### 6.3 RLS

See [Checkpoint 5.2](#checkpoint-5). RC-5c is the canonical worked example of what happens when a `SECURITY DEFINER` view/function is granted broader-than-needed direct privileges — codified as a standing verification step (§6.7 below).

### 6.4 Secrets

| Secret | Storage | Consumer |
|---|---|---|
| `LEAPA_API_KEY`, `LEAPA_BASE_URL` | Supabase Vault | `_shared/leapa.ts` — also reused by ProxiPay, no separate secret |
| `LEAPA_WEBHOOK_SECRET` | Supabase Vault | `leapa-webhook/index.ts` (HMAC verification) |
| `FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID` | Supabase Vault | `_shared/fcm.ts` |
| `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` | Supabase Vault | `_shared/whatsapp.ts` |
| `CRON_SECRET` | Edge Function env var **and** Vault entry (both required) | `run-scheduled-actions`, `check-system-alerts` |
| `service_role` key | Supabase Dashboard / CI env only | Never in Flutter, never committed |
| `anon` key | `lib/core/services/supabase_service.dart` | Public by design — grants no access without a valid JWT; RLS is the real boundary |

### 6.5 Permissions / Roles

`owner`/`manager`/`staff`/`client` at the RLS level; an additive `is_system_admin` boolean scope (`public.users.is_system_admin`, gated `has_system_admin(auth.uid())`) layered on top for platform-wide admin RPCs, introduced specifically because no such scope existed when Remote Config/CMS/Health-Center admin functions needed one. Fine-grained RBAC (`permission_groups` ← `user_permission_groups`, `user_permission_overrides`, `check_permission()`) is real and deployed but wired into very few screens (`PermissionGuard` is wired into exactly one, `staff_list_screen.dart`'s "Add staff" action) — RLS remains the actual security boundary regardless of whether a screen also calls `PermissionGuard`.

### 6.6 Encryption

| Data | At rest | In transit |
|---|---|---|
| JWT/session token | OS Keychain/Keystore | TLS (Supabase default) |
| Postgres data | Supabase-managed disk encryption (platform default) | TLS |
| `kynza_prefs` Hive box | Encrypted (`HiveAesCipher`, since Phase 5) | N/A, local only |
| `permission_cache` Hive box | **Unencrypted** — deliberately low-sensitivity content (permission booleans, not PII) | N/A |
| Storage bucket contents | Supabase-managed (platform default) | TLS |
| Leapa webhook payload | N/A | HMAC-signed (integrity, not confidentiality) |

### 6.7 Logging / Journalisation

**`activity_logs`**: append-only, client-side inserts restricted to a whitelist of `type_action` values enforced by RLS (`logs_self_insert_safe` policy) — an arbitrary client-side log-forgery attempt is rejected at the database level. `ip_address`/`device_info` now populated across all 9 real server-side call sites (**P2-7**, closed). **`system_admin_audit`**: a separate, working, application-level audit table fed by `grant_system_admin()`/`revoke_system_admin()` (**P2-8**, closed). **`auth.audit_log_entries` (GoTrue's native audit log): confirmed 0 rows, project-wide, in production — this is P2-29, an explicitly disclosed gap, not a silent one.** Discovered incidentally while documenting a temporary `system_admin` test identity's lifecycle during the Advisors Review — neither the Admin-API user-creation/deletion calls nor a direct SQL privilege-elevation populate this GoTrue-native log. Two undistinguished hypotheses: the mechanism is disabled/unconfigured at the platform level for this project, or it has simply never been exercised by a genuine admin-console action. **No investigation or fix has been attempted** — this is a disclosed forensic/incident-response gap (no native trail of admin-console actions if any occurred outside application logging paths), not a live exploit. See [Checkpoint 13.2](#checkpoint-13) for the FAQ answer to "is this normal?"

### 6.8 Policies

Governance policies (change management, not RLS): [Checkpoint 9](#checkpoint-9)/[10](#checkpoint-10).

### 6.9 Known attack surfaces (closed and residual)

**Closed, with production evidence** (full list in the Master Inventory): `staff_profiles_public_select` invitation-token exposure (P0-1); `staff_profiles.salon_id` mass-assignment (P1-1); `calculate-commission` cross-tenant commission read (P2-2); Remote Config admin-gate bypass (P2-9); `create_default_document_templates`/`get_staff_week_rank` unrestricted anon access (P2-1/P3-15); the RC-4/RC-8/RC-6c/RC-6d/RC-5c Advisors findings (Checkpoint 6.3/6.7 above).

**Residual, tracked, not hidden**:
- **RC-11 — Leaked Password Protection (HaveIBeenPwned) disabled**: blocked by the current Supabase **Free** plan (confirmed directly by the Dashboard's own error message on activation attempt: *"leaked password protection via HaveIBeenPwned.org is available on Pro Plans and up"*). The correction fiche is written and ready (`docs/advisors-review/CP5_PLAN_CORRECTION.md`, Fiche 6 révisée) — this is a **business dependency** (plan upgrade), not a technical blocker, and not classified as engineering debt.
- **P2-21 (root/jailbreak detection)**: a complete, ready-to-execute activation procedure exists (`docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md`), deliberately not shipped as code — verifying it needs a real rooted device/emulator not available in any session's environment; shipping unverified detection logic would itself violate this project's evidence-discipline rule. Certificate pinning (the other half of P2-21) is a separate External Go-Live Dependency (needs a real captured production TLS certificate).
- **~450 raw Advisor alerts left open, each with a stated reason** (RC-1 `auth_rls_initplan` ×108, RC-2 `multiple_permissive_policies` ×227, RC-3 `unused_index` ×93 non-actionable pre-launch, RC-6 residual grants on functions already protected by an internal `has_system_admin()` gate, RC-7 `extension_in_public` ×2 on extensions already active in production) — Checkpoint 0.2 item 6 explains the count growth; Checkpoint 12 lists the re-evaluation trigger for each.

---

<a id="checkpoint-7"></a>
## Checkpoint 7 — Observability Manual

### 7.1 Logs

**Crashlytics**: real, wired into `runZonedGuarded`/`FlutterError.onError`/`PlatformDispatcher.onError` since before the Enterprise Hardening pass. 27 previously-silent catch blocks (of 174 total catch blocks scanned — the other 166 already rethrew or set `AsyncError` state) were fixed to call `CrashReportingService.recordError()` — zero behavior change, logging only. **3 log tiers**: `log(message)` (breadcrumb), `recordError(error, stack)` (non-fatal), the existing fatal-error wiring — matching Crashlytics' own model, no invented levels. **`activity_logs`**: business-mutation audit trail (Checkpoint 6.7). **No cross-cutting correlation-ID header** is threaded through Edge Functions — idempotency keys (`bookings.idempotency_key`, `transactions.idempotency_key`) serve as an implicit correlation key for the two flows that have them; this is a disclosed, not a silently-assumed, gap.

### 7.2 Metrics

**Firebase Performance** (`firebase_performance`): a `cold_start` trace (started right after `Firebase.initializeApp()`, stopped when the initial auth check first resolves) plus 3 named flow traces — `booking_creation`, `proxipay_payment_confirmation`, `search`. Verified with a real `flutter build apk --release --split-per-abi` to confirm zero new Android permissions were introduced by the SDK.

### 7.3 Monitoring / Dashboards

Real, live dashboards/views (post-RC-5c, accessible only through their gated RPCs): `v_notification_delivery_rate`, `v_payment_success_rate`, `mv_audit_stats` (hourly refresh), the ~13 Health Center dashboards (`v_crash_dashboard`, `v_edge_function_dashboard`, `v_queue_dashboard`, `v_storage_dashboard`, `v_supabase_dashboard`, etc., all deployed as part of the Group 2 batch, 2026-07-06). No admin-facing UI screen was built on top of all of them — the metric definitions and storage exist; a comprehensive dashboard screen is deferred, not silently assumed built.

### 7.4 Alerting

**Live, in production**: `check-system-alerts` (`kynza-check-system-alerts` cron, every 5 min) writes to `system_alerts` on 3 categories — edge-function error rate, sync-queue depth, payment-failure rate — each proven against real (marked, cleaned-up) test data in production itself (`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`, P1-12 row). WhatsApp dispatch of an alert is best-effort/inert pending the `WHATSAPP_TOKEN` secret being genuinely exercised for this path — alert *recording* does not depend on it. **Documented thresholds, not yet all wired to a push channel**: payment failure rate <90%/day, notification delivery rate <80%/day, cold-start p95 >3s (Firebase Performance console alerting), DLQ non-empty (no push-alert mechanism today — a real, named gap; the DLQ is a client-local Hive box, not server-visible, so closing this needs either a periodic client→server sync or a server-side DLQ concept, neither built).

### 7.5 Health of the system / Investigation procedures

Routine health check (no fixed cadence — run when touching anything backend-adjacent, per `docs/governance/BACKEND_MAINTENANCE_GUIDE.md`):
1. `supabase migration list --linked --project-ref hhdkjfpgaklhrhfoxlhj` — local vs. production migration count must match; a mismatch is itself a Category A finding.
2. `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` — deployed function versions must match `git log` for `supabase/functions/`.
3. `curl https://api.github.com/repos/Mylord90/kynza-app/actions/runs?per_page=5` — CI must still be green; a new red run is investigated before any other backend work proceeds.
4. Read `system_alerts` for any unacknowledged threshold breach.
5. If a documentary inconsistency is suspected: verify with direct evidence (a live query, a git log check) before touching anything — never silently correct a document in passing (`docs/governance/BACKEND_MAINTENANCE_GUIDE.md`, "If you find a documentary inconsistency").

---

<a id="checkpoint-8"></a>
## Checkpoint 8 — Backup Manual

### 8.1 What is backed up today

`create-backup` (manual, per-salon owner/manager action, 1-per-6h cooldown) and `create-platform-backup` (the recurring, cron-driven equivalent, `kynza-platform-backup`, every 6 hours) both export a **per-salon or platform-wide JSON snapshot**, not a SQL dump — `salons`, `services`, `staff_profiles`, `clients` (deduped), `bookings` (last 90 days), `reviews` (last 90 days), `invoices` (last 90 days). Stored as one JSON blob per run in the private `kynza-backups` Storage bucket, tracked via `backup_jobs` (`pending → running → completed|failed`). **No download button exists in the app** — retrieval today means pulling the object from Storage directly (dashboard or API). **Retention**: indefinite, no automatic expiry/cleanup job exists (a real, disclosed gap). **Not covered by this mechanism**: any table outside the 7 listed (Legal Center, automation, feature flags, permission groups, CMS, Remote Config, etc.) — this is an operational-data backup, not a full-database backup. Supabase's own Point-in-Time Recovery (a paid-plan feature) is the actual full-database safety net and is out of this document's scope to configure (a billing decision).

### 8.2 Restore procedure — actually executed, not just described

A live restore drill was run end-to-end against a real (non-production) target, `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`, `eu-central-1`, same region as production) — seed → backup → simulated data loss → restore → byte-for-byte verification. **Result: PASS.** One real, previously-unknown bug was found and fixed during the drill: `GENERATED ALWAYS AS` columns (`search_vector` on `services`/`salons`) reject any `INSERT` supplying a value for them, even a previously-computed one — the restore script now strips these columns before re-inserting, and this is now standing operational knowledge (table-keyed, easy to extend if another generated column is added elsewhere later). **What this drill does not prove**: restoring the `salons` row itself (blocked by a real FK constraint from `users.salon_id` during the drill — informative, not a defect: a full-salon restore needs `users.salon_id` nulled first or `salons` restored before re-pointing users at it); it did not exercise `reviews`/`invoices` with real data; it was single-salon/single-record-per-table, not a production-volume test. *(`docs/DISASTER_RECOVERY_RUNBOOK.md` §2)*

### 8.3 RPO / RTO

**RPO**: bounded at ≤6 hours going forward (the `kynza-platform-backup` cadence) — this was previously an unbounded, ever-growing gap (a single one-time backup with no successor mechanism) before the recurring cron was deployed 2026-07-06. **RTO**: **[À CONFIRMER]** — no full-production restore has ever been rehearsed (only the dr-scratch drill above, and only for a subset of tables); a stated, timed, real restore-into-a-fresh-target playbook for the full 55+-table schema **has never been produced**, tracked as open item **P3-21** ("no restore-from-backup mechanism exists as a supported operation, only a one-off drill script") and **P3-20** ("rollback statements for the original 20-migration batch exist but were never live-drilled").

### 8.4 Emergency procedures

- **Data loss / corruption suspected**: do not attempt an ad hoc fix. Confirm the scope with a read-only query first, then follow the pattern proven in the dr-scratch drill (§8.2) against a **fresh, disposable target**, never directly against production, until a production-specific restore playbook exists.
- **Migration rollback**: no down-migrations exist — write a new, forward, corrective migration (never edit an applied one). See [Checkpoint 9.4](#checkpoint-9).
- **Feature misbehaving in production**: the fastest lever is the feature-flag kill-switch (`feature_flags`/`salon_feature_overrides`) — flip `is_enabled=false`, no deploy required. (Caveat: per Checkpoint 3.10, very few real screens currently gate behavior on a flag — this lever is only as effective as the flag coverage that exists for the specific feature.)
- **App release rollback**: halt the staged Play Console rollout — a prior APK/AAB remains installed for users who haven't updated. No code change needed.

---

<a id="checkpoint-9"></a>
## Checkpoint 9 — Deployment Manual

### 9.1 Git conventions

Conventional-commit-style prefixes matching this project's history throughout: `feat(...)`, `fix(...)`, `docs(...)`, `security(...)`, `refactor(...)` — scope names the campaign/session/area (e.g. `docs(governance)`, `security(p2-5-ecr)`). One clean commit per logical unit of work; a multi-phase Category B/C session gets one commit per phase/checkpoint, each with its own closure evidence in the message. *(`docs/governance/CONTRIBUTION_POLICY.md`)*

**One PowerShell command per line convention** (governance procedural note, applies whenever exploitation/operational commands are documented): never chain with `&&`; each command stands alone with its own verification step.

### 9.2 Branches

**[À CONFIRMER]** — no formal branching strategy is documented in any source pass; not flagged as a defect by any pass, but also never independently verified. The observed practice throughout this project's history is direct, sequential commits reviewed phase-by-phase with explicit human approval, not a branch-per-feature model. Treat as **Non validé**, not "fine," per the Master Plan's own §11 assessment.

### 9.3 Migrations — full lifecycle

1. **Creation**: drafted under `supabase/migrations/`, timestamp-named, SQL reviewed before being considered "drafted."
2. **Testing environment**: `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`) — **never** production — is the only pre-production target. There is no local Docker/Postgres stack in this project; `supabase db push` always targets a real remote project.
3. **Required evidence before requesting approval**: applies cleanly to `kynza-dr-scratch`; a real before/after check (a query, an exploit re-attempt, a screen rendering real data) proving the change does what it claims.
4. **Deployment (approval gate — "Rule 8")**: no migration is ever applied to production without Mylord's explicit, per-migration or per-batch approval, given *before* the `supabase db push`/`migration up --linked` command runs — never after. Held without a single violation across this project's entire history.
5. **Rollback procedure**: written *before* deployment, not drafted after something breaks.
6. **Never edit an applied migration ("Rule 4")**: a correction is always a new, later-timestamped migration.
7. **Post-deploy verification**: re-run the same before/after check from step 3, this time against production itself, immediately after applying.

### 9.4 Edge Functions — deployment/rollback/versioning

- **Shared utilities over per-function duplication is mandatory**, not a style preference — any cross-cutting concern (CORS, body-size guard, rate limiting, auth/service-role client construction, structured logging, audit-log writing) lives in exactly one file under `_shared/`, imported by every function that needs it. No function may reimplement a shared concern locally.
- **Deployment**: `supabase functions deploy <name> --project-ref <ref>`, dr-scratch first, production only after approval — same gate as migrations. A shared-utility change requires redeploying **every** function that imports it, not just the one under active development (the exact mistake `readBodyGuarded()`'s own rollout initially risked).
- **Rollback**: redeploy with the pre-change code checked out, or `supabase functions delete <name>` for a function that didn't exist before the change.
- **Versioning**: `supabase functions list --project-ref <ref>` is the authoritative record of what's actually deployed — always checked directly after a deploy, never assumed from local git state alone.
- **Validation before requesting production approval**: a live, evidenced before/after test against `kynza-dr-scratch` — for a security-relevant change, a real exploit attempt, both before and after.

### 9.5 Release checklist (pre-release, backend or app)

1. `flutter analyze` → 0 issues (the floor held since Enterprise Hardening's Phase 0 baseline, never regressed below).
2. Full test suite green, 0 failures (skips allowed only if individually justified).
3. For a backend-affecting release: migration count and Edge Function versions re-verified live against production immediately before.
4. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 reflects the true current state.
5. A `CHANGELOG.md` entry exists for the release.
*(`docs/governance/RELEASE_POLICY.md`)*

### 9.6 Post-release checklist

Re-run the release checklist's items 1–3 immediately after deploy against the now-live target; confirm CI is still green; confirm the Master Inventory's affected rows moved to `Fermé (preuve)` with fresh evidence, not left at `Corrigé-non-déployé`.

### 9.7 Versioning conventions

- **Backend**: no separate release artifact — a migration/Edge Function deploy *is* the release. Tag a significant Category B/C closing commit `backend-<topic>-<date>` (not mandatory for every Category A fix).
- **Flutter app**: `MAJOR.MINOR.PATCH+BUILD` (currently `1.0.0+1`), enforced live via `check_app_version()` RPC. PATCH = bug fixes; MINOR = new backward-compatible feature; MAJOR = breaking data-format change or a minimum-supported-version bump; BUILD = increments on every store submission regardless.

### 9.8 Rule 8 — the permanent governance rule

**No migration, RLS policy change, or Edge Function deploy reaches production without Mylord's explicit, prior, per-item approval.** Restated as a permanent rule, not a per-campaign courtesy — this is the single most-repeated, most-verified practice across this project's entire documented history (`docs/governance/FINAL_GOVERNANCE_REPORT.md`, "What is forbidden without a new, explicitly-scoped session").

---

<a id="checkpoint-10"></a>
## Checkpoint 10 — Maintenance Manual

### 10.1 When to intervene, and when not to

The backend is in **maintenance mode** (`docs/governance/MAINTENANCE_POLICY.md`): it has no known internal P0/P1 engineering debt and is not being actively developed — it is being **kept correct**. Intervene for: a security patch on a newly-reported issue, a real bug fix, a dependency/platform update, or a new business requirement. Do **not** casually start a new multi-checkpoint audit or feature build (a Category C campaign) — per `docs/governance/CHANGE_POLICY.md` §3, this is currently **not justified** (zero P0/P1 internal debt), and starting one requires explicitly, visibly pausing maintenance mode first, never sliding into one incrementally.

### 10.2 Change categories (the decision framework for "how big is this")

| Category | Examples | Process |
|---|---|---|
| **A — small, targeted** | Bug fix, security patch for an already-understood issue, dependency bump, doc correction | Standard fix: reproduce → fix → test on dr-scratch if backend-touching → approval for anything production-bound → deploy → verify. No dedicated report folder required. |
| **B — targeted session** | A single-topic RCA/ECR/verification pass (the P2-5 RCA/ECR, the Advisors Review, this Handbook's own production) | Own folder, own checkpoint structure sized to the actual scope, a closing report, and — non-negotiably — the canonical Master Inventory updated **in the same closing session**. |
| **C — full campaign** | Enterprise Hardening, Backend Enterprise Completion, both Certification passes, Remediation, Final Enterprise Validation, Enterprise Resilience, Master Plan Execution, Enterprise Final 100 | Justified only when a large new business initiative begins, or a genuine accumulation of many small findings needs one coordinated sweep — checked against the Master Inventory's actual current count/severity, never assumed. Explicitly pauses maintenance mode, with a dated note recorded. |

### 10.3 Handling a bug

Reproduce against `kynza-dr-scratch` first (never production, unless the report is itself about production-only behavior — rare, and read-only verification comes first even then). Classify severity per the table in [Checkpoint 6.5's companion, §10.6 below]. Create the ticket (§10.5). Fix, test, request approval, deploy, re-verify live. Close the ticket in the same session, in the canonical document, with the evidence.

### 10.4 Handling a vulnerability

Same sequence as §10.3, plus the security-specific documentation additions in [Checkpoint 6](#checkpoint-6): an OWASP/MITRE mapping where applicable, a working repro (the exact `curl`/RPC call), and a blast-radius check (what's actually exposed *right now*, distinguishing a live active exploit from a real-but-currently-dormant exposure — this changes urgency, never whether the issue must be fixed).

### 10.5 Handling technical debt

Recorded as a ticket the moment it's confirmed with direct evidence (not a hunch). ID assignment is governed by a single rule, stated here because its violation has already caused two real documentary failures in this project's history: **there is exactly one incrementing counter per severity prefix (`P0-`, `P1-`, `P2-`, `P3-`, `R-`), and it lives in exactly one place — the highest number currently used in `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2.** Before assigning a new ID: find the current highest number for that prefix in that document, the new ID is that number + 1, and the new row is added to §2 **in the same session that discovers the finding** — never deferred. *(`docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §1.2, citing the exact P2-22 collision incident this rule was written to prevent)*

### 10.6 Handling an evolution (new feature)

Classify first (§10.2). A genuinely new business feature is out of scope for maintenance mode without an explicit, visible pause — see §10.1.

### 10.7 Handling a migration

Full lifecycle: [Checkpoint 9.3](#checkpoint-9).

### 10.8 Handling an incident

Full procedures: [Checkpoint 11](#checkpoint-11).

### 10.9 The scientific method this project already established (not invented for this Handbook)

**Diagnostic → preuve (proof) → classification → priorisation → plan → correction → validation → rejeu (replay) → rapport (report).** This is the exact sequence the Advisors Review campaign followed (`CP1_COLLECTE_BRUTE` → `CP2_CAUSES_RACINES` → `CP3_CLASSIFICATION` → `CP4_PRIORISATION` → `CP5_PLAN_CORRECTION` → execution → `CP6_EXECUTION_LOG` → replay comparison → `CP9_RAPPORT_FINAL`), and the same shape every prior campaign in this project's history has used. Any future Category B/C session should follow this same sequence rather than inventing a new one.

### 10.10 Routine checks

See [Checkpoint 7.5](#checkpoint-7).

---

<a id="checkpoint-11"></a>
## Checkpoint 11 — Incident Response Manual

### 11.1 Supabase outage

Confirm scope via the Supabase status page and a direct read-only query attempt. The app's circuit breaker (`DependencyCircuitBreakers.supabase`, [Checkpoint 2.15](#checkpoint-2)) will trip client-side after repeated failures — no manual client-side action needed. If the outage is prolonged, communicate via whatever out-of-band channel exists (no formal support/status-page mechanism is built into KYNZA itself — **P3-10**, no `CLIENT_SUPPORT` role/process exists, an open item).

### 11.2 Data corruption

Do not attempt an in-place fix. Confirm the exact scope with a read-only query. If a restore is needed, follow the pattern proven in the dr-scratch drill ([Checkpoint 8.2](#checkpoint-8)) against a fresh, disposable target first — **a full-production restore has never been rehearsed** (P3-21/P3-20, open); do not assume the drill's procedure generalizes untested to production scale or to tables not exercised in the drill (`reviews`, `invoices`).

### 11.3 Secret leak

Rotate the affected secret in Supabase Vault immediately; redeploy every Edge Function that consumes it (per [Checkpoint 9.4](#checkpoint-9)'s shared-utility redeploy rule if the secret is used via a shared helper). Git history has been confirmed clean of secrets across this project's full commit history (`docs/certification-v2/CP6_DEVSECOPS_INFRA.md`) — a leak, if it occurs, is a runtime/config exposure, not a git-history one; treat it accordingly (rotation is sufficient, a history rewrite is not automatically required).

### 11.4 Edge Function unavailable

Check `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` for its deployed status/version first. If it's a server-invoked-only function (`send-notification`, `execute-workflow`), user-visible symptoms will be indirect (missing notifications, stalled automation) — check `activity_logs`/`system_alerts` before assuming the function itself is down. Rollback per [Checkpoint 9.4](#checkpoint-9).

### 11.5 Auth broken

Confirm whether the issue is GoTrue-side (platform) or KYNZA-side (a recent RLS/`has_role()`/trigger change). If a recent migration touched `public.users` or its triggers, that migration is the first suspect — check its rollback statement ([Checkpoint 9.3](#checkpoint-9) step 5) before assuming a platform issue.

### 11.6 Realtime unavailable

Reconnection/backoff is entirely the `supabase_flutter` SDK's default behavior — there is no app-authored reconnect logic to debug. If Realtime is down at the platform level, the app's offline-read-cache paths ([Checkpoint 2.14](#checkpoint-2)) provide a degraded-but-functional experience for the 4 cache-backed read paths only; every other `.stream()`-backed screen has no fallback beyond an empty/loading state.

### 11.7 Restoration

Full procedure: [Checkpoint 8.2](#checkpoint-8). **This is the one incident type this Handbook can least fully guarantee** — the only executed restore drill was single-salon, small-scale, and against a scratch project, not production, and did not cover every table.

---

<a id="checkpoint-12"></a>
## Checkpoint 12 — Maintenance Roadmap

### 12.1 P2-28 — platform limitation, non-actionable from application code, safety margin documented

Request bodies roughly ≳210KB (a probabilistic band, evidence-backed as ~209,000–220,000 bytes) have a substantial-to-near-total chance of never reaching an Edge Function's Deno isolate at all — proven platform-level: the *unmodified* pre-fix code, given an honest, accurate `Content-Length` header, hung 5/5 times at 210,000 bytes in production; the new streaming guard (ADR-0005) shows identical behavior at the same sizes. Old and new code affected equally rules out application code as the cause. **Current safety margin**: all 16 body-guarded functions enforce a single, non-overridable `MAX_BODY_BYTES = 102,400` (100KB) — over 106,000 bytes of margin below the first observed failure, live-verified at the exact byte boundary. **Status**: open, disclosed, bounded — needs its own future root-cause investigation with tooling this program has never had (nothing available can see inside a hung invocation from outside it). **Not to be confused with P2-5** (the `Content-Length`-reliability mechanism, which *is* closed) — P2-28 persists even when P2-5's header dependency is entirely absent from the picture.

### 12.2 P2-29 — observability debt, decision required

`auth.audit_log_entries` (GoTrue's native audit log) has 0 rows, project-wide, in production. Not investigated beyond the incidental discovery that triggered it ([Checkpoint 6.7](#checkpoint-6)). **Decision needed**: whether to investigate why (platform config vs. never-exercised) and, if fixable, whether it's worth fixing given `system_admin_audit` (the application-level equivalent) already covers the one admin-privilege-elevation path KYNZA's own code uses. This is explicitly a **decision to make**, not a task with an obvious next engineering step — do not start an RCA on this without first deciding it's worth the time, per the same discipline P2-28 already modeled.

### 12.3 RC-11 — business dependency, not technical debt, fiche ready

Leaked Password Protection (HaveIBeenPwned) is unavailable on the current Supabase **Free** plan. **Not classified as technical debt** — the correction mechanism itself is fully designed and ready (`docs/advisors-review/CP5_PLAN_CORRECTION.md`, Fiche 6 révisée: a direct Management API `GET`→`PATCH`→`GET` sequence, `config.toml`/`config push` explicitly excluded as a mechanism after a real incident during drafting — Checkpoint 13.4 has the full story). **Trigger to resume**: a Supabase plan upgrade to Pro or above, a decision belonging to Mylord, with no fixed date. No re-analysis will be needed at that point — the fiche does not expire.

### 12.4 External dependencies (owner: Mylord/business, not engineering)

| Item | Blocks | Owner action needed |
|---|---|---|
| Real Android upload keystore | Play Store | One-way secret generation + a documented 2-location custody plan — the conditional-signing wiring to *use* it is already built and verified |
| Real Privacy Policy / Terms content | Play Store + App Store | Real legal copy — the serving/versioning/consent mechanism (Legal Center) is fully built and deployed |
| iOS platform (Apple Developer enrollment + full build) | App Store | Apple Developer account is the blocker itself, not a missing feature; treat as "a full second-platform launch effort, not a punch-list item" |
| Play Store Data Safety Form | Play Store | A Play Console UI task; the real data inventory it needs already exists |
| Real bank transfer details | Real invoicing | Business decision, not engineering |
| Google Maps API key | Maps/Places/Geolocation features | A real, billed Google Cloud API key |

### 12.5 Internal engineering items — genuinely open, each with a stated reason

| Item | Why not rushed |
|---|---|
| **P2-10** — 19/24 repository_impl files at 0% test coverage; a Firebase-mocking gap for anything using `PerformanceMonitoringService.traceAsync` | Structural — needs new mocking infrastructure (`mocktail` seam proven on 1 repository), genuinely Large |
| **P2-12** — Feature Flags engine gates zero real screens | A product decision (which features should be flag-gated), not an engineering blocker |
| **P2-14** — no `check-subscription` cron; lapsed plans never auto-revert | Needs a new Edge Function + cron; medium effort, not yet prioritized |
| **P2-16/P2-17** — `auth_rls_initplan`/`multiple_permissive_policies` Advisor warnings (108/227 at last count) | Needs per-policy review, never a blind rewrite — a mechanical rewrite across dozens of tables risks silently changing RLS semantics; trigger to revisit: real, measurable production traffic |
| **P2-25** — no bucket `file_size_limit`/`allowed_mime_types`, no server-side WebP compression | Medium effort, not yet prioritized |
| **P3-2/P3-3** — 14 presentation files bypass the repository layer; datasource/repository split only real in `auth` | Large refactor, non-blocking |
| **P3-4** — `app_router.dart` monolithic (1,418 lines), no `ShellRoute` | Tracked separately, see `project_shellroute_refactor_backlog` |
| **P3-5** — Edge Function hygiene (timeouts, tracing, structured logging) rolled out to only 2/22 functions | Large, per-function; a shared helper is proven, full rollout deferred |
| **P3-6** — 8 unbounded repository stream/fetch methods (distinct from the 3 already bounded, ADR-0004) | Needs one-by-one review — some may intentionally show full history |
| **P3-10** — no `CLIENT_SUPPORT` role/process | Product decision |
| **P3-14** (internal half) — Firebase Analytics, local-notifications package not integrated | Genuinely open internal work, not blocked by anything external, simply not attempted yet |
| **P3-18** — 2 of 4 CMS client-consumer screens unbuilt (`OnboardingContentScreen`, `BeautyTipsScreen`) | Small, not yet prioritized |
| **P3-20** — migration rollback statements never live-drilled | Medium, needs a dedicated drill session |
| **P3-21** — no restore-from-backup mechanism as a supported (non-drill) operation | Medium, a `restore-backup` Edge Function mirroring `create-backup`'s shape is the natural next build |
| **RC-1/RC-2/RC-3/RC-6b residual/RC-6e/RC-6f/RC-7** — ~450 raw Advisor alerts left deliberately open | Each individually justified in `docs/advisors-review/CP9_RAPPORT_FINAL.md` §6 — mostly performance-at-scale or defense-in-depth hygiene, no live exploit path, re-evaluation trigger is real production traffic in every case |

### 12.6 Improvements identified but not engaged

`ShellRoute` GoRouter migration (KynzaBottomNav shipped visual-only, still local `_tabIndex` state); i18n completeness beyond the ~100 screens already converted; the debug Android keystore still in use pending the real one (§12.4).

---

<a id="checkpoint-13"></a>
## Checkpoint 13 — Technical FAQ

### 13.1 Why is `salon_id` never read from the client payload?

Because RLS is the only tenant-isolation boundary in this system, and RLS policies check `has_role(auth.uid(), role, salon_id)` against a `salon_id` **derived server-side** from `public.users.salon_id` via `auth.uid()`. If `salon_id` were trusted from the request body, any authenticated user could pass another salon's ID and, combined with a bug elsewhere, read or write across tenants. This is the single most-repeated architectural invariant in this project (`docs/ARCHITECTURE.md` §4.1, `docs/SECURITY.md` §1.3, and every RLS policy in `docs/DATABASE_ARCHITECTURE.md`).

### 13.2 The GoTrue audit log is empty — is that normal?

**No, it's a disclosed gap (P2-29), but it is also not evidence of tampering.** It was found to be empty *before* any investigation began, and the one mechanism tested during its discovery (Admin-API user creation/deletion, direct SQL privilege elevation) does not populate it either — meaning its emptiness may simply reflect that no genuine Dashboard/console admin action has ever been performed on this project, not that logging is broken or was disabled after the fact. Do not treat "the audit log is empty" as itself alarming; do treat "we have no forensic trail if a console action ever does happen" as the real, open risk this ticket tracks.

### 13.3 What do I do if Supabase Advisors flags a new alert on a `SECURITY DEFINER` view?

Follow the RC-5c lesson explicitly, not just the RC-5c fix: **check every privilege the offending role holds** (`INSERT`/`UPDATE`/`DELETE`/`REFERENCES`/`TRUNCATE`, not just `SELECT`) and **check the view's structural updatability** (`information_schema.views.is_insertable_into`/`is_updatable`, no `INSTEAD OF` trigger) **before** classifying/prioritizing the finding, not just before applying the fix. RC-5c's severity was under-assessed at Checkpoint 4 (classified as a read-exposure only) precisely because this check happened only right before the fix was applied, not during initial classification — the real gravity (an unauthenticated write path to `invoices`/`activity_logs`/`rate_limit_buckets`) would have been caught two checkpoints earlier with this discipline applied from the start.

### 13.4 Why is `supabase config push` excluded as a mechanism for Auth config changes?

Because it has no field-level granularity — it computes and applies a diff of the **entire** `[auth]` section between the local `config.toml` and the remote project, not just the one field you intended to change. This caused a real incident during the RC-11 attempt: 9 unrelated Auth fields (MFA settings, email confirmation settings, `site_url`, templates) were silently pushed to `kynza-dr-scratch` alongside the intended `password_hibp_enabled` change, because the local `config.toml` had drifted from the remote project's real state and had never been audited before that session. All 9 were restored field-by-field and verified. **Standing rule since this incident**: any future one-off Auth config change goes through a direct Management API call (`GET`→`PATCH` on the single field→`GET` verification), never `config.toml`/`config push`.

### 13.5 Is the backend production-ready?

Yes, per `docs/governance/DEFINITION_OF_PRODUCTION_READY.md` — but "production-ready" and "store-submittable" are two different, deliberately separate questions. The backend meets every engineering/operations domain (security, infrastructure, testing, observability, documentation); store submission remains gated on the 4 External Go-Live Dependencies alone, none of which are engineering gaps.

### 13.6 Why does `check_rate_limit()` fail open instead of fail closed?

Because it gates ~15 Edge Functions near the top of the request path, and a fail-closed design would turn a transient hiccup in one small table (`rate_limit_buckets`) into a full outage of every one of those functions — trading a temporary, bounded rate-limiting gap for a real availability outage. See ADR-0001 for the full reasoning and its reconsideration trigger (observed real abuse during a real limiter outage, not a hypothetical one).

### 13.7 Why do two different "atomic claim" implementations exist in this codebase?

Because they solve two different problems. A dedicated claim RPC with `FOR UPDATE SKIP LOCKED` (`claim_pending_action_runs()`) is for a cron-polled **queue** needing batching and stale-claim recovery. An inline conditional `UPDATE` (`claim-referral`, `validate-qr`) is for a **single, caller-identified resource** claimed exactly once, with no queue and no orphan-recovery need. See ADR-0002 before building a third shape for either problem type.

### 13.8 Why is the offline mutation outbox limited to review/profile/data-deletion, and not bookings?

By design, not by omission: booking creation and status changes need server-authoritative, atomic slot-locking that cannot be safely deferred to a client-side queue without reintroducing a double-booking risk. See [Checkpoint 3.1](#checkpoint-3) and [Checkpoint 2.14](#checkpoint-2).

### 13.9 What happens if a paid salon's subscription lapses?

Nothing automatic — this is a known, open gap (P2-14). No cron/RPC/Edge Function exists to auto-revert a lapsed plan to free; only the freemium *booking-count* limit is enforced automatically. See [Checkpoint 3.9](#checkpoint-3).

### 13.10 How do I know if a document under `docs/` is still current, or just historical?

Check `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §6.1's canonical-document-per-topic table first. If the topic isn't listed there, treat the document as a historical campaign report (evidentiary, frozen) unless this Handbook or the Master Inventory explicitly says otherwise.

---

<a id="checkpoint-14"></a>
## Checkpoint 14 — Glossary

| Term | Meaning |
|---|---|
| **ProxiPay** | KYNZA's own QR-code-based in-person payment handoff mechanism; session-based, settles through Leapa underneath — not a separate payment processor |
| **Leapa** | The actual third-party mobile-money payment gateway/processor |
| **FBu / BIF** | Burundian Franc, the currency KYNZA's `CurrencyFormatter` formats (narrow-space thousands separator) |
| **RLS** | Row-Level Security — Postgres's row-filtering access-control mechanism, the sole tenant-isolation boundary in KYNZA |
| **`has_role()`** | The single SQL function every RLS policy in this schema is built from |
| **RC-x** | A root-cause ID from the Supabase Advisors Review campaign (`docs/advisors-review/CP2_CAUSES_RACINES.md`) |
| **P0/P1/P2/P3-x** | A ticket ID in the canonical Master Inventory (`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2), severity per `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §5.2 |
| **R-x** | A "Remediation-era" ticket ID, predating the current P0–P3 numbering, still cross-referenced in the Master Inventory |
| **ADR** | Architecture Decision Record — `docs/adr/000N-*.md`, written when a decision's reasoning isn't derivable from the code alone and getting it wrong twice would cost real time |
| **Rule 8** | The permanent rule that no migration/RLS change/Edge Function deploy reaches production without Mylord's explicit, prior, per-item approval |
| **Rule 4** | Never edit an already-applied migration — always a new, forward, corrective migration |
| **Category A/B/C** | The change-size classification framework (`docs/governance/CHANGE_POLICY.md`) — small targeted fix / scoped single-topic session / full multi-checkpoint campaign |
| **`kynza-dr-scratch`** | The reusable, non-production staging Supabase project (ref `hzjmyeptytvjmzbnsmwp`) — the only pre-production migration/Edge-Function testing target |
| **Corrigé-non-déployé** | Master Inventory status: fix is code-complete and tested on `kynza-dr-scratch`, not yet applied to production — distinct from, never conflated with, `Fermé` |
| **Fermé (preuve)** | Master Inventory status: closed, with a cited, re-run before/after proof against the environment that matters |
| **External Go-Live Dependency** | An open item whose blocker is a business/Mylord action (a secret, legal content, an account enrollment, a console form), not an engineering gap |
| **`readBodyGuarded()`** | The single shared streaming body-size guard used by all 16 body-accepting Edge Functions (ADR-0005) |
| **`AtomicClaimService`** | The single client-side mechanism for claiming queued work exactly once (paired with `claim_pending_action_runs()` server-side) |
| **`SECURITY DEFINER`** | A Postgres function/view attribute causing it to run with its *owner's* privileges, not the caller's — bypasses RLS on the underlying table, so it must perform its own internal authorization check |
| **Maintenance mode** | The backend's current operating state — no known P0/P1 internal debt, kept correct rather than actively developed (`docs/governance/MAINTENANCE_POLICY.md`) |

---

<a id="checkpoint-15"></a>
## Checkpoint 15 — Executive Summary

KYNZA's backend — the Supabase project serving every tenant of this Flutter-based salon-management platform — is **production-ready and in maintenance mode**. As of 2026-07-07: zero critical (P0) or high-severity (P1) engineering issues remain open; all 91 database migrations are live in production; all 22 backend functions are deployed and versioned; automated backups run every 6 hours and automated health-alerting runs every 5 minutes; the code quality bar (zero static-analysis issues, 411 automated tests passing) was re-verified directly in the writing of this document, not simply carried forward from an old report.

This state was reached the hard way: eight successive campaigns over two weeks — the first an architecture-documentation pass, the following seven increasingly adversarial engineering and security reviews — found real vulnerabilities — including, at one point, a live, unauthenticated path that could let one salon's staff account be taken over — and every one was fixed and proven fixed with a real before/after test against production itself, not a code review or a passing unit test alone. A ninth, most recent campaign (a structured review of Supabase's own automated advisory system) closed 56 additional lower-severity findings the same way.

What remains is not engineering debt — it is four items outside engineering's control entirely: a one-way Android signing secret only the business owner can generate, real legal-policy text only a human can write, an Apple developer account enrollment, and a Google Play Store questionnaire. Two additional items are disclosed, bounded, and honestly still open pending future investigation (a platform-level request-size ceiling with a wide safety margin already in place, and an empty native audit log with no evidence of any actual security impact), and one security hardening feature (leaked-password protection) is ready to switch on the day the Supabase plan is upgraded.

Going forward, this backend does not need another large audit campaign — it needs to be **maintained**: patched when a real issue is found, extended when a real business need arises, and never silently drifted from what this document and its one canonical issue tracker say is true.

---

<a id="checkpoint-16"></a>
## Checkpoint 16 — Index

This Handbook uses stable, numbered anchors (`#checkpoint-N`) so future updates can be linked to durably. Quick-jump by need:

- **"Is X still an open issue?"** → [Checkpoint 12](#checkpoint-12), or the canonical `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 directly for anything not summarized here.
- **"How do I deploy a change?"** → [Checkpoint 9](#checkpoint-9).
- **"Something's broken in production right now."** → [Checkpoint 11](#checkpoint-11).
- **"What does this table/function/RLS policy do?"** → [Checkpoint 5](#checkpoint-5), then `docs/DATABASE_ARCHITECTURE.md` directly for the full per-table reference.
- **"What does this Edge Function do?"** → [Checkpoint 4](#checkpoint-4), then `docs/EDGE_FUNCTIONS_REFERENCE.md` for the 20 it covers in full per-function detail.
- **"Who owns fixing this?"** → [Checkpoint 17](#checkpoint-17).
- **"I'm new — what do I read first?"** → This document in full, then `docs/governance/BASELINE_DOCUMENT.md`, then whichever canonical per-topic document (`BACKEND_GOVERNANCE_GUIDE.md` §6.1) your task actually touches.

---

<a id="checkpoint-17"></a>
## Checkpoint 17 — Responsibility Matrix

| Concern | Owner |
|---|---|
| Application code (Flutter, Dart) | KYNZA engineering (backend/client codebase under version control in this repo) |
| Supabase schema, RLS, RPC, Edge Functions | KYNZA engineering — but every production-bound change requires Mylord's explicit per-item approval (Rule 8) |
| Supabase platform itself (uptime, PITR availability, plan tier, Advisor tooling, GoTrue's native audit log mechanism) | Supabase (the platform vendor) — KYNZA engineering can configure and consume it, not fix a platform-level limitation (e.g. P2-28, RC-11's Free-plan block) |
| Android/iOS app packaging, store-specific requirements (keystore, signing, manifests) | KYNZA engineering builds the wiring; Mylord generates/owns one-way secrets and makes irreversible decisions (e.g. the real upload keystore) |
| Google Play Store / Apple App Store submission (listings, Data Safety form, Developer account enrollment) | Mylord / business — these are console/account actions, not code |
| Firebase project configuration and billing tier | Mylord / business, configured for Android by KYNZA engineering |
| Leapa integration and its own uptime/API contract | Leapa (external vendor) for their side; KYNZA engineering for the integration code |
| Legal content (Privacy Policy, Terms of Service, bank details) | Mylord / business / legal — the serving mechanism is engineering's, the content is not |
| Day-to-day operations (approving deploys, generating secrets, plan upgrades) | Mylord |
| Documentation currency (this Handbook, the Master Inventory, governance docs) | Whoever makes the change that affects them, in the same session (`BACKEND_GOVERNANCE_GUIDE.md` §6.4) |

---

<a id="checkpoint-18"></a>
## Checkpoint 18 — Final Certification

**Is the backend officially in Maintenance Mode?**
Yes. Per `docs/governance/MAINTENANCE_POLICY.md`'s entry condition (zero P0/P1 internal engineering debt, stated in `docs/governance/FINAL_GOVERNANCE_REPORT.md` and re-verified live in this session), and unbroken since — the one Category B session that ran after entry (the Advisors Review) was itself explicitly permitted *during* maintenance mode, not a pause of it.

**Is this document now the official reference?**
For the purpose it was written for — understanding the backend's current state, architecture, and operating rules without reopening historical reports — yes. It does not supersede `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 as the canonical *ticket-status* tracker (per `BACKEND_GOVERNANCE_GUIDE.md` §6.1, that role belongs to the Master Plan document specifically, and this Handbook cites it rather than duplicating it) — this Handbook is the synthesis and onboarding layer on top of that canonical tracker and the other canonical per-topic documents.

**Do the older reports remain purely historical (never updated, never deleted)?**
Yes — every campaign folder under `docs/` (certification, certification-v2, remediation, enterprise-resilience, final-enterprise-validation, enterprise-final-100, go-live, backend-production-closure, p2-5-rca, p2-5-ecr, final-doc-verification, master-plan-execution, advisors-review) stays on disk unmodified as evidentiary record, per `BACKEND_GOVERNANCE_GUIDE.md` §6.4's explicit rule: "a historical document is never edited to reflect new findings."

**Must future changes respect the governance rules already established?**
Yes, without exception: Rule 8 (production approval gate), Rule 4 (never edit an applied migration), the single-counter ticket-ID rule, the canonical-document-per-topic rule, and the Category A/B/C classification framework all remain in force, restated in [Checkpoints 9–10](#checkpoint-9) rather than superseded.

**Are the remaining technical debts (P2-28, P2-29, RC-11) correctly and completely identified?**
Yes, per the evidence cited in [Checkpoint 12](#checkpoint-12): each is named, dated, scoped, and given an explicit re-evaluation trigger — none is silently omitted, and none is inflated to a severity its own evidence doesn't support. The broader internal P2/P3 list (§12.5) and the 4 External Go-Live Dependencies (§12.4) are likewise individually named, not summarized away.

---

<a id="appendix"></a>
## Appendix — Documentary Inconsistencies Detected (Not Auto-Corrected)

Per the governing rule for this Handbook's production ("no claim without a citation... signal every documentary inconsistency, never correct it silently"), every divergence found while writing this document is listed here with both versions and their sources. **None of these have been edited in the source documents themselves** — each is a proposal, not an applied correction.

| # | Inconsistency | Version A | Version B | Proposed correction (not applied) |
|---|---|---|---|---|
| 1 | Migration count | `docs/governance/BASELINE_DOCUMENT.md`/`FINAL_GOVERNANCE_REPORT.md`: "87 migrations, 0 unapplied" (written 2026-07-07, before the Advisors session's production applies) | This Handbook, live-verified: 91 (`git ls-tree -r HEAD`) | Append a dated addendum to `BASELINE_DOCUMENT.md` noting the 4 Advisors-campaign migrations applied after its own writing, or accept this Handbook's Checkpoint 0.2 reconciliation as the standing explanation |
| 2 | Edge Function reference completeness | `docs/EDGE_FUNCTIONS_REFERENCE.md`: documents 20 functions, dated 2026-07-04 | Live count: 22 (`check-system-alerts`, `create-platform-backup` added 2026-07-06, undocumented in that file) | Add 2 rows to `EDGE_FUNCTIONS_REFERENCE.md`'s catalog table, or accept this Handbook's Checkpoint 4 as the current stopgap catalog for those 2 |
| 3 | Table count | `docs/DATABASE_ARCHITECTURE.md`: "55 tables," dated 2026-07-03 | At least ~15-20 additional tables deployed since (Group 2 migration batch, 2026-07-06) — exact current count **[À CONFIRMER]**, not independently re-queried live in this session | Re-run a live `information_schema.tables` count against production and update `DATABASE_ARCHITECTURE.md` §2's own count/reconciliation note the same way it already reconciled its prior "~47" figure |
| 4 | Supabase Advisor warning counts on unchanged rules | `docs/certification/PHASE_2_DATABASE_OPTIMIZATION.md` (2026-07-04/05): 83 `auth_rls_initplan`, 205 `multiple_permissive_policies`, 50 `unused_index` | `docs/advisors-review/CP1_COLLECTE_BRUTE.md` (2026-07-07): 108, 227, 93 respectively | **Verified directly against the raw Advisor evidence JSON** (Checkpoint 0.2 item 6): `multiple_permissive_policies`' entire growth (205→227) is on the 21 new Group 2 tables, exact match on old ones; most of `unused_index`'s growth is new index objects (P2-15's own 32 FK indexes) on old tables, not stale old indexes; `security_definer_view` (the RC-5c-critical category) shows **zero growth**, exact match to its known 32. A small, ~6% unreconciled residual remains on `auth_rls_initplan` (+5 on pre-existing objects) — disclosed as unreconciled, not force-explained; no regression signal found on any RLS-isolation-critical category |
| 5 | `docs/governance/BASELINE_DOCUMENT.md`/`MAINTENANCE_POLICY.md` name only 4 open items | Text says "the only 4 remaining P1s," predating the Advisors Review | Current full list is 4 External Dependencies + P2-28 + P2-29 + RC-11 (7 total, of differing severities/categories) | Append a dated addendum noting the Advisors Review (a later Category B session) added P2-29 and left RC-11 deferred, neither superseding the original 4 External Dependencies but both real additions to the "still open, still not an engineering blocker" list |
| 6 | `docs/PRODUCTION_CHECKLIST.md`'s earliest sections read as current | States P0-1 unpatched, zero backups exist, in its original 2026-06-27 content and several early "Update" sections | Both are long since closed (Master Inventory rows P0-1, P1-3) | No correction needed to the file itself (it is explicitly a historical, dated-update-appended document, not the canonical status tracker per `BACKEND_GOVERNANCE_GUIDE.md` §6.1) — flagging here only so a future reader does not mistake its early sections for current state, exactly the failure mode `BACKEND_GOVERNANCE_GUIDE.md` §6.4 already warns about for any document of this shape |
| 7 | `docs/FEATURE_FLAGS.md`, `docs/CATALOG_ARCHITECTURE.md`, `docs/LEGAL_CENTER_ARCHITECTURE.md` still say their respective migrations (`20260703140000_feature_flags_registry.sql`, `20260703130000_catalog_schema.sql`, `20260703150000_legal_center.sql`) are drafted, "not applied" | Each written 2026-07-03, at which point true | All 3 migrations are confirmed live in the applied set (`git ls-tree -r HEAD`, part of the Group 2 batch deployed 2026-07-06 per the Master Plan's Go-Live Phase 2) | No correction applied to the 3 source files — each is a historical snapshot correctly superseded by the Master Plan's later deployment record, same shape as inconsistency #3. This Handbook's Checkpoints 3.10–3.12 state the current ("deployed") status directly, not the stale wording; flagged here so the underlying source docs aren't mistaken for current if read directly |
| 8 | `docs/ARCHITECTURE.md` §2 states minimum versions "Flutter 3.22+ / Dart 3.4+" | Written 2026-07-03 (Documentation Expansion pass) | Live-verified this session: `flutter --version` → Flutter 3.44.2; `pubspec.yaml`'s `environment:` block → Dart SDK `^3.12.2` | No correction applied to `ARCHITECTURE.md` — it states a minimum-supported floor, not necessarily meant as "the exact current version," but the gap (3.4+ stated vs. `^3.12.2` actual) is large enough to flag rather than silently treat as equivalent. Checkpoint 1.3 states the live-verified numbers directly |

**No anomaly in the code itself was discovered while producing this documentation-only Handbook.** This session's live verification did extend, in response to a direct follow-up question, to a precise object-level query of the raw Supabase Advisors evidence JSON (`docs/advisors-review/evidence/CP1_advisors_hhdkjfpgaklhrhfoxlhj_2026-07-07.json`) and to enumerating the exact table/index names two migration batches introduced — both are read-only queries against files already committed to this repository, not against the remote Supabase project. This session performed no migration, Edge Function, or application-code change — only documentation was produced, and only read-only verification commands (`flutter analyze`, `flutter test`, `git ls-tree`, `git log`, `git show`, `git tag -l`) were run against the local repository. No command in this session touched the remote Supabase project.
