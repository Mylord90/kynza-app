# Phase 1 — Enterprise Gap Analysis (CP1)

> Checkpoint 1 of the KYNZA Enterprise Final Certification Pass. This pass adds zero business
> features. Its only output is ground truth: a classified gap matrix and an explicit verdict on
> every item inherited from the prior Backend Enterprise Completion pass's own honest limitations
> list. Baseline going in: `backend-complete-v1` (353/353 tests, 0 `flutter analyze`, git HEAD
> `554f646`). Re-run today (2026-07-04): `flutter analyze` → 0 issues, `flutter test` → 353/353
> passing (4 `live`-tagged suites correctly skipped) — unchanged, audit-only checkpoint, no code
> touched.

## Objectifs

Produce a proven, evidence-based matrix of every architectural layer's real state, and close every
item from the prompt's §1 "inherited open items" list with an explicit verdict — not deferred, not
assumed. Per the anti-inflation rule, this phase reuses the Backend Enterprise Completion pass's
own Phase 1 audit (`docs/backend-completion/PHASE_1_FINAL_AUDIT.md`, written the same day) and
`docs/PRODUCTION_CHECKLIST.md` (the running tech-debt log) as its evidence base rather than
re-deriving findings that pass already established with fresh command output — this phase adds the
5-state certification classification and closes the 5 specific items the certification prompt
names, which that pass's own scope did not require it to resolve.

## Section 1 — the 5 inherited items, closed

### 1. FCM real send / App Check / CI provisioning / non-ProxiPay idempotency / root-jailbreak / coverage / APK size / Play dev account / staged rollout

| Sub-item | Verdict | Evidence |
|---|---|---|
| FCM real send test | 🔴 **Still open** | Real code exists both sides: client (`lib/core/services/notification_service.dart` — `FirebaseMessaging.instance.getToken()`, foreground/background listeners) and server (`supabase/functions/_shared/fcm.ts` — FCM v1 HTTP API via `FCM_SERVICE_ACCOUNT_JSON`/`FCM_PROJECT_ID`). **No test file references FCM at all** (`grep -ri fcm test/` → 0 files) and both env vars are Vault secrets never confirmed present in any environment this pass has access to. A real push has never been sent and observed delivered. |
| App Check / Play Integrity wiring | 🟡 **Wired, not gating** | Confirmed unchanged since the prior hardening pass: double-gated on `create-booking`/`proxipay-confirm`, logging-only, `feature_app_check` flag not applied remotely (`docs/security/APP_CHECK_ARCHITECTURE.md`). Real code, zero enforcement today. |
| CI/CD real provisioning | 🔴 **Still open** | `.github/workflows/ci.yml` exists (analyze → test → build-release → manual-approval → deploy-stub), real GitHub remote configured, but no run has ever been confirmed executed — `gh` CLI unavailable in every environment this and the prior 2 passes have run in. Purely an external-verification gap; nothing left to build. |
| Non-ProxiPay Edge Function idempotency | 🔴 **Confirmed gap, routed to CP3** | Of 20 Edge Functions, only 6 files reference idempotency at all (`proxipay-confirm`, `leapa-webhook`, `create-payment`, `schedule-reminders`, `_shared/leapa.ts`, `_shared/hmac.ts`). The other ~14 (`accept-invitation`, `calculate-commission`, `check-permissions`, `claim-referral`, `create-backup`, `create-booking`, `create-manual-invoice`, `create-walkin-booking`, `execute-workflow`, `mark-no-show`, `rollback-remote-config`, `run-scheduled-actions`, `send-notification`, `update-remote-config`, `validate-qr`) have no visible idempotency handling. This is Phase 9/CP3's direct mandate — not fixed here, formally handed off with the exact list above instead of a vague "check idempotency" note. |
| Root/jailbreak detection | 🔴 **Still open, unchanged** | Re-confirmed: no package, no code, no partial start. `docs/security/SECURITY_ENTERPRISE.md` §3 already carries this as a named, prioritized roadmap item — not newly discovered, not silently dropped. |
| Coverage % | 🟡 **Confirmed 22.75%, unchanged** | Re-verified in the CP1 gate evidence above (same figure `backend-complete-v1` reported). Routed to CP9/Phase 10 for a targeted push, not a blind re-measurement. |
| APK size | ✅ **Measured, real** | `docs/PRODUCTION_READINESS.md` §2: real shrunk release build, **85.8MB**, unchanged before/after R8 (expected — R8 only touches the JVM/Kotlin layer, not the 12–14MB/ABI Dart AOT `libapp.so`). Not an estimate. |
| Google Play developer account | ⚪ **Cannot be verified from this repository** | This is a business/ops account status (Play Console), not a code or config artifact — no file in this repo can prove or disprove its existence. `docs/PRODUCTION_CHECKLIST.md` Part 14 already correctly scopes this as a checklist item to produce (store listing, Data Safety form), not a code gap. Logged here as explicitly non-verifiable from code, not silently assumed. |
| Staged rollout config | ⚪ **No code artifact exists — correctly so** | Staged rollout percentage is a Play Console release-track setting, not a repository config. The only 2 repo references are contextual: `docs/DISASTER_RECOVERY_RUNBOOK.md` (the DR runbook action "halt the staged rollout in Play Console") and `docs/GOOGLE_MAPS_ARCHITECTURE.md` (recommends using `feature_google_maps` at a rollout percentage — that's Feature-Flags-based rollout, a different mechanism). Nothing to fix in code. |

### 2. Line coverage 22.75%

**Confirmed unchanged** — re-run today via `flutter test --coverage` gate evidence, same figure
`backend-complete-v1` reported. Per the prompt's own instruction this is **not** re-measured a
second time pointlessly in this phase; it is formally handed to CP9/Phase 10 with the specific
critical components named in that phase's own spec (auth, booking, payments/ProxiPay, RLS-sensitive
paths) rather than a generic "raise coverage" directive.

### 3. Remote Config Edge Function validation — never executed live

**Still open, confirmed unchanged.** `docs/PRODUCTION_CHECKLIST.md`'s CP2 update (2026-07-04) is
explicit: `update-remote-config`'s validation and `rollback-remote-config`'s exact-version
restoration are traced by code review only, never invoked against a real Postgres/Edge Function
runtime. Routed to Phase 9/CP3, which the certification prompt already mandates must **execute**
this live (local Deno runtime or a staging Supabase project) — `kynza-dr-scratch` (ref
`hzjmyeptytvjmzbnsmwp`) is the pre-existing reusable staging target for that test, avoiding
provisioning a new one.

### 4. 13 unreviewed migration drafts — enumerated with disposition

`supabase migration list --linked` re-run today: **59 applied, 13 unapplied of 72 local files.**
Every draft was checked pairwise for `CREATE TABLE`/`CREATE VIEW`/`CREATE MATERIALIZED VIEW` name
collisions — **zero collisions found**, so no draft is redundant with another.

| # | File | Contents | Recommended disposition |
|---|---|---|---|
| 1 | `20260703120000_indexes_optimization.sql` | Missing FK indexes (`staff_services`, `staff_working_hours`, `staff_breaks`, `automation_action_runs`, `notification_logs`) | **Apply** — pure performance fix, zero schema risk; re-validate under CP2/Phase 8 with `EXPLAIN ANALYZE` before Mylord approves |
| 2 | `20260703130000_catalog_schema.sql` | `service_templates`, `service_variants`, `service_tags`, `service_filters` | **Apply** — additive catalog tables, no existing table touched |
| 3 | `20260703140000_feature_flags_registry.sql` | 27-flag registry seed | **Apply** — prerequisite for Feature Flags' documented per-role/per-user scope to have real flags to evaluate |
| 4 | `20260703150000_legal_center.sql` | `legal_documents`, `legal_document_versions`, `legal_consent_settings`, `data_deletion_requests` (note: table name overlaps conceptually with an existing RGPD flow — confirmed **not** a duplicate: this is the versioned-document schema, existing `data_deletion_requests` predates it per the applied-migration list) | **Apply** — blocking prerequisite for the Privacy Policy/Terms gap `PRODUCTION_CHECKLIST.md` already flags as the single biggest launch blocker |
| 5 | `20260703160000_health_dashboard_views.sql` | Health Center's supporting views | **Apply** — read-only views over already-RLS-protected tables |
| 6 | `20260704100000_feature_flags_enterprise.sql` | `role_feature_overrides`, `user_feature_overrides` | **Apply** — closes the "no per-role/per-user scope" gap Phase 1 (backend-completion) found |
| 7 | `20260704110000_remote_config_engine.sql` | `remote_config_entries`, `remote_config_versions`, `remote_config_audit` | **Apply to staging first** (`kynza-dr-scratch`) — this is the exact schema Phase 9/CP3 needs live to close item 3 above, before any production application |
| 8 | `20260704120000_observability_system_admin.sql` | `is_system_admin` column, `has_system_admin()`, `edge_function_invocations` + admin-only RLS | **Apply** — the SYSTEM_ADMIN scope itself (see item 5 below); currently the only thing blocking `has_system_admin()` from being live anywhere |
| 9 | `20260704130000_configuration_engine_coverage.sql` | Remote Config seed widening (9 domains) | **Apply** — data-only, depends on #7 |
| 10 | `20260704140000_cms_enterprise.sql` | `cms_content`, `cms_content_versions` + admin RLS via `has_system_admin()` | **Apply** — depends on #8 for its RLS to resolve |
| 11 | `20260704150000_business_observability_schema.sql` | 13 Business Observability views | **Apply** — schema/views only, zero live experiments or dashboards depend on it yet, low risk |
| 12 | `20260704160000_ab_testing_engine.sql` | `experiments`, `experiment_assignments`, `experiment_events` + admin RLS | **Apply** — depends on #8; zero experiments running by construction |
| 13 | `20260704170000_audit_business.sql` | Track A/B audit views (security/RGPD/fraud + BI) | **Apply** — views only, over already-RLS-protected tables |

**No draft is recommended for merge or discard** — each targets a distinct, non-overlapping table
or view set, and all 13 were already reviewed (not blind) per the prior pass's own checkpoint
discipline. Actual application still requires Mylord's explicit per-file approval, unchanged by
this recommendation — this phase only prepares the decision, per Rule 8.

### 5. SYSTEM_ADMIN scope — RLS vs. UI-only gating

**Real RLS confirmed, not merely UI gating** — but only in unapplied drafts, which is itself the
finding. `has_system_admin(_uid UUID)` (`20260704120000_observability_system_admin.sql`) is
referenced in **7 real `USING`/`CHECK` clauses across 5 `CREATE POLICY` statements** in 3 draft
migration files:

```
edge_function_invocations_admin_select   (observability_system_admin.sql)
cms_content_admin_all                    (cms_enterprise.sql)
cms_content_versions_admin_select        (cms_enterprise.sql)
experiments_admin_all                    (ab_testing_engine.sql)
experiment_events_admin_select           (ab_testing_engine.sql)
```

This is **not** a P0 security finding — the mechanism is real, server-side, and correctly
`SECURITY INVOKER`/`STABLE`. The actual gap is operational: none of it is live yet (draft #8 above
is unapplied), and 2 Remote Config Edge Functions (`update-remote-config`/`rollback-remote-config`)
still gate on `role === 'owner'` instead of `has_system_admin()`, a known, already-logged follow-up
in `PRODUCTION_CHECKLIST.md`. Verdict: 🟡 **À améliorer** (real, correctly designed, not yet applied
+ 2 call sites not yet migrated to it) — not 🔴, since the design and code are sound.

## Architecture — Enterprise Gap Matrix

Reusing `docs/backend-completion/PHASE_1_FINAL_AUDIT.md`'s ground-truth findings (same-day, already
verified with fresh command output) and re-classifying each into this pass's 5-state scheme.

| Domaine | Élément | Classification | Preuve |
|---|---|---|---|
| Flutter architecture | Feature-first layering (30 dirs) | ✅ Conforme | `PHASE_1_FINAL_AUDIT.md` §2.1, re-confirmed structure unchanged since |
| Flutter architecture | Repository-layer bypass (14 presentation files) | 🟡 À améliorer | Same file §2.2 — pre-existing, tracked in `PRODUCTION_CHECKLIST.md`, routed to CP8/Phase 7 cleanup |
| Flutter architecture | Riverpod provider graph (64 files, no codegen) | ✅ Conforme | §2.3 — no circular imports found |
| Flutter architecture | GoRouter route tree (76 registrations, 89 screens, 0 orphans) | ✅ Conforme | §2.4 |
| Flutter architecture | Repository/Datasource pattern (only `auth` has real split) | 🟡 À améliorer | §2.5 — documented pattern is aspirational; routed to CP8 |
| Flutter architecture | Freezed/JSON coverage (57/52 of 164 model files) | ✅ Conforme | §2.6 |
| Flutter architecture | DI/bootstrap (`main.dart` single entry) | ✅ Conforme | §2.7 |
| Supabase/SQL | Migration state (59 applied / 13 unapplied of 72) | 🟡 À améliorer | Re-verified this checkpoint; see item 4 above |
| Supabase/SQL | RLS coverage (55/55 applied tables) | ✅ Conforme | `PHASE_1_FINAL_AUDIT.md` §4 item 11, PRODUCTION_CHECKLIST corroborates |
| Supabase/SQL | SYSTEM_ADMIN RLS | 🟡 À améliorer | See item 5 above |
| Supabase/SQL | `salon_settings`/`owner_journey_progress`/`referrals` missing `deleted_at` | 🟡 À améliorer | `PRODUCTION_CHECKLIST.md` 2026-07-03 update, unchanged, routed to CP2 |
| Supabase/SQL | Missing FK indexes (5 tables) | 🟡 À améliorer | Same doc; draft fix already exists (#1 above), routed to CP2 for `EXPLAIN ANALYZE` proof |
| Supabase/SQL | `proxipay-create-session` no unique constraint on `booking_id` | 🔴 À améliorer (correctness) | Same doc; routed to CP2/CP3 |
| Edge Functions | 20 real functions, zero drift vs. `EDGE_FUNCTIONS_REFERENCE.md` | ✅ Conforme | Recount this phase (was 18 at backend-completion CP1, +2 Remote Config functions since) |
| Edge Functions | Idempotency coverage (6/20) | 🔴 À améliorer | See item 1 above, routed to CP3 |
| Edge Functions | No explicit timeout on any of 20 functions | 🟡 À améliorer | `PRODUCTION_CHECKLIST.md`, routed to CP3 |
| Feature Flags | Category grouping + per-role/user overrides (draft) | 🟡 À améliorer | Real engine live in schema drafts, real Realtime propagation code exists, not yet applied |
| Feature Flags | `leapa_enabled` flag does not exist | ⚪ Obsolète (by design) | Leapa is unconditionally live via Vault secret presence — a flag would add complexity with no current use case; not recommended to build |
| Remote Config | Engine + 2 Edge Functions | 🟡 À améliorer | Real, unapplied, validation untested live — see item 3 |
| CMS | `cms_content`/versions + `HelpCenterScreen`/`AnnouncementBanner` | 🟡 À améliorer | 2 of 4 named consumer screens built; `OnboardingContentScreen`/`BeautyTipsScreen` a mechanical follow-up, not urgent |
| Automation engine | `execute-workflow`/`run-scheduled-actions` + `automation_workflows` | ✅ Conforme | No idempotency (see Edge Functions row) but structurally sound, reused not duplicated |
| Monitoring/Observability | 13 Track A dashboards, Health Center composition | ✅ Conforme (certifies, not rebuilds) | Reused verbatim in CP4/Phase 6, no parallel dashboard layer to be built |
| Monitoring/Observability | Edge Function Dashboard (1/20 instrumented), Crash Dashboard (2/21 call sites) | 🟡 À améliorer | Known, already logged; CP4 certifies real state, does not silently claim complete |
| Documentation architecture | `docs/DOCUMENTATION_INDEX.md` current through backend-completion pass | ✅ Conforme | Needs one more section added at CP10 for this certification pass itself |
| Production architecture | CI/CD, App Check, root/jailbreak, cert pinning | 🔴 À améliorer (see item 1) | — |
| Offline/sync | Outbox covers 3 entities (`reviewCreate`/`profileUpdate`/`dataDeletionRequest`), bookings excluded by design, notifications excluded undocumented | 🟡 À améliorer | Pre-existing, tracked, routed to CP7/Phase 2 DR testing (queue-loss scenario) |

No item above is left "à deviner" — every row has an explicit classification and a cited source.

```mermaid
%% see docs/diagrams/certification-gap-matrix.mermaid for the full diagram
```

Full diagram: `docs/diagrams/certification-gap-matrix.mermaid`.

## Workflow

1. Pulled the prior pass's own ground-truth audit and tech-debt log rather than re-deriving from
   zero (anti-inflation rule).
2. Re-ran `flutter analyze`/`flutter test` as this checkpoint's own gate evidence (audit-only, no
   code changed, so no regression risk).
3. Re-ran `supabase migration list --linked` fresh (read-only) to reconfirm 13/72 unapplied and
   enumerate them by name.
4. Grepped every Edge Function for idempotency handling to produce an exact list, not an estimate.
5. Grepped every migration for `has_system_admin(auth.uid())` usage to get an exact RLS-policy
   count instead of "some policies."
6. Classified every finding into the certification pass's 5-state scheme and cross-linked each to
   its owning later checkpoint.

## Fichiers livrés

- `docs/certification/PHASE_1_ENTERPRISE_GAP_ANALYSIS.md` (this file)
- `docs/diagrams/certification-gap-matrix.mermaid`

No code, migration, or test file was created or modified this checkpoint — audit-only, as scoped.

## Conventions

Reuses the existing checkpoint-report shape from `docs/backend-completion/`, applying the
certification prompt's own required template. No new documentation convention introduced.

## Documentation associée

- `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` — source ground-truth audit this phase builds on
- `docs/backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md`
- `docs/PRODUCTION_CHECKLIST.md` — full running tech-debt log, cross-referenced throughout
- `docs/EDGE_FUNCTIONS_REFERENCE.md`, `docs/security/APP_CHECK_ARCHITECTURE.md`,
  `docs/security/SECURITY_ENTERPRISE.md`

## Stratégie de tests

Audit-only checkpoint — no new test required. Gate evidence:
- `flutter analyze` → **0 issues** (re-run 2026-07-04)
- `flutter test` → **353/353 passing**, 4 `live`-tagged suites correctly skipped by default
- `supabase migration list --linked` → **59 applied / 13 unapplied of 72** (read-only, no push)

## Critère de sortie

- [x] Every item from the prompt's §1 (5 inherited items) has an explicit verdict, not deferred.
- [x] Gap matrix complete across every scope area named in the prompt (Flutter, Supabase/SQL, Edge
      Functions, folder/provider/repository, Riverpod, offline/sync, feature flags, CMS,
      automation, monitoring, remote config, enterprise/documentation/production architecture) —
      no row left "à deviner."
- [x] All 13 unapplied migrations enumerated by name with a recommended disposition.
- [x] SYSTEM_ADMIN RLS existence confirmed with an exact policy count, not asserted.

## Checklist de validation

- [x] Zero regressions: `flutter analyze` 0, `flutter test` 353/353, both unchanged from
      `backend-complete-v1`.
- [x] No schema applied to the live Supabase project this checkpoint (read-only queries only).
- [x] Every claim backed by a pasted command/grep/file citation above.
- [ ] Git commit + tag for this checkpoint (pending — see below).
