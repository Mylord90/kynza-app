# KYNZA â Backend Enterprise Completion (Phases 1-11)
### Prompt for Claude Code â Execute in `D:\KYNZA-PROJET`

---

## 0. ROLE & CONTEXT

You are a Staff Software Architect completing the **final backend/infrastructure layer** of
KYNZA before it is declared backend-complete. Phases 1-11 of the prior roadmap (Documentation
Architecture, Enterprise Hardening) are closed: `post-hardening-v1` tag, 326/326 tests,
0 `flutter analyze`. After this pass, only these should remain: UI Premium, final legal content,
marketing assets, Leapa go-live, Google Maps go-live, Play Store / App Store submission.

**This is additive/industrialization work. Never modify existing business logic, screens, RLS
policies, or workflows that already work â only complete, harden, and make the infrastructure
configurable.**

---

## â ï¸ MANDATORY SEQUENCING NOTE â READ BEFORE EXECUTING

The phases below are split into two tracks. **This split is a hard execution rule, not a
suggestion** â it exists because KYNZA has not yet shipped V1.0 or acquired a single live salon,
and instrumentation built for traffic that doesn't exist yet is waste that delays real launch.

- **Track A â build fully now.** True infrastructure completion: audit, core observability
  (technical dashboards, not business BI), Feature Flags engine, Remote Config engine, security/
  RGPD/fraud audit tooling, CMS for Help/FAQ/onboarding content (needed for launch support), and
  the final completion checklist.
- **Track B â build the schema/engine only, defer the UI/analysis layer.** Business
  Observability (cohorts/LTV/MRR/ARR/Churn), A/B Testing engine, and the financial/commission/
  subscription audit dashboards. For these: build the data model, the write-path, and the
  provider/repository layer so nothing needs re-architecting later â but **do not build the
  analysis UI/dashboards themselves in this pass**. They are meaningless without real production
  data and would be dead code sitting unused until post-launch traction exists.

Every phase below is tagged **[TRACK A]** or **[TRACK B â schema/engine only]** accordingly.
If Mylord explicitly overrides this for a specific phase, note the override in that phase's
report and proceed as directed.

---

## 1. ABSOLUTE RULES (carried forward, unchanged)

Zero regressions (`flutter analyze` = 0, all tests green at every phase checkpoint) Â· Feature-
First + Clean Architecture + Riverpod + GoRouter + Freezed Â· every new table: RLS + `deleted_at`
+ incremental migration, never destructive Â· no business logic in widgets Â· PowerShell only, one
command per line, never `&&` Â· no physical deletion Â· **no draft migration/seed applied to the
live Supabase project without explicit per-file approval** Â· one scoped git commit per phase +
checkpoint tag Â· every phase report includes actual command output as evidence, never assumption.

---

## GLOBAL DELIVERABLE TEMPLATE (per phase, unless noted)

```
docs/backend-completion/<PHASE_NAME>.md
## 1. Objectifs
## 2. Architecture (+ Mermaid diagram(s) in docs/diagrams/)
## 3. Workflow / Data Flow
## 4. Fichiers livrÃ©s (exact paths)
## 5. Conventions & Structure
## 6. Migrations SQL / nouvelles tables (if any)
## 7. Nouvelles Edge Functions (if any)
## 8. Tests (unit/widget/integration, what's covered)
## 9. Documentation associÃ©e
## 10. CritÃ¨res de validation
## 11. Checklist de sortie (Exit Criteria)
```

---

## PHASE 1 â BACKEND ENTERPRISE FINAL AUDIT `[TRACK A]`

**Objectif:** ground-truth audit before any change â same discipline as the prior hardening
pass's Phase 0/1, extended to full backend depth.

**Audit scope (verify with actual commands/queries, never assume):**
- Flutter: architecture layering, Riverpod provider graph (no circular deps), GoRouter route
  tree completeness, Repository/Datasource pattern consistency, Freezed/JSON serializable
  coverage, dependency injection wiring.
- Supabase: full schema dump vs. documented schema (reconcile any new drift since Phase 2 of the
  prior pass), every Edge Function, every migration file vs. applied state, every RLS policy
  (test cross-tenant access per table, not just read the policy text), every index, every view,
  every trigger, every RPC function, every FK constraint.
- Offline/Sync: outbox queue coverage per entity, DLQ health, conflict resolution correctness
  (re-verify the integration tests from the prior pass still pass).
- Security/Perf/Memory/Battery: re-run the Phase 5/8 measurements from the prior hardening pass,
  diff against baseline â flag any regression.
- Feature Flags/RBAC/Permissions/Billing/Notifications/Firebase/Storage/CI-CD/Monitoring: confirm
  current real status against the `âª Ã  vÃ©rifier` items from the last audit report â this phase
  must close every remaining unknown from that report.

**Livrable:** `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` â full findings, each item marked
â/ð¡/ð´ with evidence, no unresolved âª left at the end of this phase.

**Exit Criteria:**
- [ ] Every item from the previous audit's "âª Ã  vÃ©rifier" list is now closed with evidence.
- [ ] Any newly discovered gap is logged and assigned to the correct Phase 2-11 below (or to
      `docs/PRODUCTION_CHECKLIST.md` if out of this prompt's scope).

---

## PHASE 2 â OBSERVABILITY ENTERPRISE `[TRACK A â technical dashboards]` / `[TRACK B â business-facing ones, schema only]`

**Objectif:** real technical visibility into the running system. Note the split within this
phase itself:

**Build fully now (technical/ops dashboards â Track A):** Health Dashboard, System Metrics,
Crash Dashboard, Sync Dashboard, Queue Dashboard, Edge Function Dashboard, Realtime Dashboard,
Supabase Dashboard, Storage Dashboard, Notification Dashboard, Performance Dashboard, Security
Dashboard, Network Dashboard.

**Schema/data-pipeline only, no UI yet (Track B):** Analytics Dashboard, Audit Dashboard,
Business Dashboard, Battery Dashboard, Memory Dashboard â these need either real user volume
(Analytics/Business) or are more useful as periodic reports than live dashboards pre-launch
(Battery/Memory, already measured once in Phase 8 of the hardening pass).

**Architecture (each Track A dashboard):**
- SQL view or materialized view in Supabase feeding the metric (e.g. `v_sync_queue_health`,
  `v_edge_function_latency`).
- Riverpod provider polling/subscribing (Realtime where it makes sense, polling with sane
  interval elsewhere â never a tight poll loop that burns battery/bandwidth).
- Admin-only screen (RBAC-gated, likely OWNER + a new internal `SYSTEM_ADMIN` scope if none
  exists â do not expose to regular OWNER/STAFF roles).
- Each dashboard must itself work in the 5 UI states and must degrade gracefully offline (show
  last-cached snapshot, not a blank error).

**Livrable:** `docs/backend-completion/PHASE_2_OBSERVABILITY.md`, SQL views, Dart
providers/screens for Track A items, data model only for Track B items.

**Exit Criteria:**
- [ ] Every Track A dashboard renders real data from a real query, verified against actual
      current system state (not mock data).
- [ ] Track B items have a documented schema and a one-line note on what's needed to activate
      the UI later (data volume threshold, or post-launch trigger).

---

## PHASE 3 â FEATURE FLAGS ENTERPRISE `[TRACK A]`

**Objectif:** upgrade the existing `feature_flags` table/system (already documented in the prior
pass) into a genuinely dynamic, no-redeploy engine.

- Confirm/extend flag scope granularity: global, per-salon, per-user, per-role (Booking,
  Loyalty, Referral, Promotion, Analytics, Reviews, Subscriptions, Commission, Notifications,
  ProxiPay, Google Maps, Leapa, Staff/Owner/Client/Manager feature sets, Beta, Experimental).
- Realtime propagation: a flag flip in Supabase must reach connected clients without an app
  restart (Realtime subscription on `feature_flags`, cached in Hive for offline reads).
- Kill-switch semantics documented per flag: what exactly happens to in-flight state when a flag
  is disabled mid-session (must never corrupt data, must degrade to one of the 5 UI states).
- Admin UI: flag list, toggle, scope editor, audit trail of who changed what and when (ties into
  Phase 10's audit engine).

**Livrable:** migration (if schema extension needed), `docs/backend-completion/
PHASE_3_FEATURE_FLAGS_ENGINE.md`, updated `docs/FEATURE_FLAGS.md`.

**Exit Criteria:**
- [ ] A flag toggled in Supabase reaches a running app instance without restart â proven by a
      test, not a description.
- [ ] Every flag category from the list above is represented and independently toggleable.

---

## PHASE 4 â REMOTE CONFIGURATION `[TRACK A]`

**Objectif:** a versioned, auditable remote-config engine â the backbone that Phase 8 will
extend.

**Data model:**
```
remote_config_entries   (id, key, category, value_json, value_type, description,
                          updated_by, updated_at, deleted_at)
remote_config_versions  (id, entry_id, version_number, value_json, changed_by, changed_at,
                          change_reason)
remote_config_audit     (id, entry_id, action, actor_id, occurred_at, before_json, after_json)
```
- Categories to cover: prices, commissions, subscription tiers, quotas, promotional colors/
  theming tokens, onboarding copy keys, FAQ entries (cross-link to Phase 9's CMS rather than
  duplicating storage), announcements, maintenance-mode toggle, rate limits, feature-flag
  defaults, sync/timeout intervals, notification templates, workflow parameters, misc business
  configuration.
- Every write goes through an Edge Function (`update-remote-config`) that validates the value
  against a per-key JSON schema before accepting it â a malformed config value must never reach
  clients.
- Rollback: one-click revert to any prior version via `remote_config_versions`.
- RLS: read = authenticated (scoped to what's relevant to their role), write = service-role only.

**Livrable:** migration, `update-remote-config` Edge Function, Riverpod provider with Hive
offline cache (config must be usable offline from last-fetched values), admin UI (list, edit,
version history, rollback button), `docs/backend-completion/PHASE_4_REMOTE_CONFIG.md`.

**Exit Criteria:**
- [ ] A config value changed remotely is reflected client-side without redeploy â proven.
- [ ] Rollback to a prior version tested and proven to restore exact prior state.
- [ ] Malformed value write attempt rejected by the validating Edge Function â proven by test.

---

## PHASE 5 â HEALTH CENTER `[TRACK A]`

**Objectif:** the real-time supervision **surface** â this is the UI/aggregation layer sitting on
top of Phase 2's Track A dashboards. **Do not rebuild the underlying metrics a second time** â
Health Center consumes the same SQL views/providers from Phase 2 and composes them into one
supervision screen with drill-down, rather than duplicating data pipelines.

- Single-screen overview: CPU/RAM/Storage/Network client-side telemetry (via Firebase
  Performance, already wired), Realtime channel health, Queue depth, Notification delivery rate,
  Edge Function latency/error rate, Crash rate, Sync health, Slow query log (Supabase), RPC
  health, Hive box sizes/health.
- Alert banner integration: surfaces the Phase 4-hardening-pass alerting thresholds visually,
  not just via external notification.
- Must be genuinely real-time where the underlying data supports it (Realtime-subscribed), and
  clearly timestamped/stale-marked where it's polled.

**Livrable:** `docs/backend-completion/PHASE_5_HEALTH_CENTER.md`, composed admin screen.

**Exit Criteria:**
- [ ] No metric pipeline is duplicated from Phase 2 â Health Center is proven to be a composition
      layer (code review note confirming shared providers, not copy-pasted queries).
- [ ] Screen correctly distinguishes real-time vs. polled vs. stale data visually.

---

## PHASE 6 â BUSINESS OBSERVABILITY `[TRACK B â schema/pipeline only, no dashboard UI]`

**Objectif:** make sure the data model exists so that once KYNZA has real salons/bookings/
revenue, building the actual BI dashboards is a UI task, not a data-modeling task. **No
dashboard screens in this phase.**

- Data model / views covering: revenue, salons (active/churned), staff, clients, subscriptions,
  commissions, bookings, cancellations, payments, loyalty engagement, referrals, growth,
  conversion, activation, retention, cohorts, LTV, ARPU, MRR, ARR, churn, revenue forecast
  inputs.
- Build these as SQL views/materialized views over existing tables (`bookings`, `transactions`,
  `subscriptions`, `invoices`, `staff_commissions`, `referrals`, `loyalty_cards`) â no new raw
  data collection beyond what already exists, since KYNZA doesn't yet generate the volume that
  would justify a new event-tracking pipeline.
- Document exactly which metrics will show `0`/`null` meaningfully until real usage exists vs.
  which are computable today from QA data (be explicit about this so no one mistakes an empty
  chart for a broken one, later).

**Livrable:** SQL views, `docs/backend-completion/PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md`
(explicitly marked: dashboards intentionally deferred to post-launch).

**Exit Criteria:**
- [ ] Every metric listed has a corresponding view/query that runs without error against current
      (even near-empty) data.
- [ ] Document explicitly states the activation trigger for building the dashboard UI later
      (e.g. "once >10 live salons with 30 days of booking history").

---

## PHASE 7 â A/B TESTING `[TRACK B â engine only, no live experiments]`

**Objectif:** the experiment infrastructure, inert until launch.

**Data model:**
```
experiments        (id, key, name, hypothesis, status, variant_config_json, started_at,
                     ended_at, deleted_at)
                    -- status: draft | running | paused | concluded
experiment_assignments (id, experiment_id, user_id, variant, assigned_at)
experiment_events  (id, experiment_id, user_id, event_key, occurred_at)
```
- Assignment engine: deterministic hashing (user_id + experiment key) so a user always gets the
  same variant â no server round-trip needed to determine assignment, works offline.
- Integrates with the Feature Flags engine (Phase 3) rather than duplicating it â an experiment
  variant can gate a flag, not reinvent gating logic.
- **Do not launch any real experiment in this pass.** No live A/B test on onboarding/CTA/colors
  etc. â that requires real traffic and a product decision on what to test, which is premature
  pre-launch.

**Livrable:** data model, assignment service, `docs/backend-completion/
PHASE_7_AB_TESTING_ENGINE.md` explicitly marked "engine ready, first experiment TBD post-launch."

**Exit Criteria:**
- [ ] Assignment is deterministic and offline-capable â proven by test.
- [ ] Zero experiments are actually running at the end of this phase (by design).

---

## PHASE 8 â CONFIGURATION ENGINE `[TRACK A â extends Phase 4, does not duplicate it]`

**Objectif:** widen what Phase 4's Remote Config engine covers, rather than building a second
parallel system. Ensure these business domains are configurable through the **same**
`remote_config_entries` schema: working hours defaults, commission rules, booking workflow
parameters (cancellation window, no-show grace period), loyalty rules, payment method
availability per region, promotion rule templates, subscription tier definitions, quota
thresholds, role/permission defaults.

**Livrable:** additional `remote_config_entries` seed rows + per-domain validation schemas +
`docs/backend-completion/PHASE_8_CONFIGURATION_COVERAGE.md` mapping each business domain to its
config keys.

**Exit Criteria:**
- [ ] No new config storage mechanism introduced â confirmed reuse of Phase 4's tables.
- [ ] Every listed business domain has at least one live, testable config key.

---

## PHASE 9 â CMS ENTERPRISE `[TRACK A â needed for launch support]`

**Objectif:** genuinely useful pre-launch, since Help/FAQ/onboarding content is needed the moment
real users exist â unlike Track B items, this isn't premature.

**Data model:**
```
cms_content       (id, type, slug, locale, title, body_markdown, status, published_at,
                    deleted_at)
                   -- type: faq | help_article | announcement | tutorial | onboarding_step |
                   --       guide | banner | promotion | beauty_tip | support_info
cms_content_versions (id, content_id, version_number, body_markdown, changed_by, changed_at)
```
- Reuses the versioning pattern established in Phase 3's Legal Center (`legal_document_versions`)
  for consistency â do not invent a third versioning pattern in the same codebase.
- Admin UI: create/edit/publish/unpublish, locale-aware (FR/EN), preview before publish.
- Client-side rendering: `HelpCenterScreen`, `AnnouncementBanner`, `OnboardingContentScreen`,
  `BeautyTipsScreen` â all consuming `cms_content` via Riverpod, offline-cached in Hive.
- Legal documents (Phase 3 of the prior pass) remain in their own table â do not migrate them
  into `cms_content`, they have distinct legal-acceptance semantics.

**Livrable:** migration, Dart source, `docs/backend-completion/PHASE_9_CMS_ENTERPRISE.md`.

**Exit Criteria:**
- [ ] Content editable and published without app redeploy â proven.
- [ ] Offline read of last-cached CMS content works â proven by test.

---

## PHASE 10 â AUDIT BUSINESS `[TRACK A for security/RGPD/fraud/sync/error/performance]` / `[TRACK B for financial/commission/subscription/loyalty audit reports]`

**Objectif:** a genuine audit engine, split the same way as Phase 2.

**Build fully now (Track A):** security audit trail (already partially covered by `AuditLogger`
â extend coverage to any remaining unlogged sensitive action), RGPD audit (data access/export/
deletion request trail â ties into Legal Center's `data_deletion_requests`), fraud audit
(anomaly flags on ProxiPay sessions â reuse replay-protection logging from the hardening pass),
synchronization audit (DLQ/outbox failure trail), error audit (Crashlytics non-fatal aggregation,
already wired in the hardening pass â formalize into a queryable audit view), performance audit
(periodic snapshot report, not live dashboard â ties to Phase 2's deferred Battery/Memory items).

**Schema only, report deferred (Track B):** financial audit, accounting audit, user-behavior
audit, salon-performance audit, payment-volume audit, loyalty-engagement audit, subscription-
churn audit, commission-accuracy audit, automation-execution audit â these produce meaningless
reports against near-zero production data; build the underlying `automation_execution_logs`/
`activity_logs`-derived views now, generate the first real report once there's data to audit.

**Livrable:** `docs/backend-completion/PHASE_10_AUDIT_ENGINE.md`, Track A audit views + admin
screens, Track B views only (no screens).

**Exit Criteria:**
- [ ] Every Track A audit type produces a real report against current QA/system data.
- [ ] Track B views run without error but are explicitly marked "awaiting production data" in
      the doc.

---

## PHASE 11 â BACKEND COMPLETION CHECKLIST (FINAL GATE)

**Objectif:** the single source of truth deciding whether "backend done" is true.

Verify and document, with evidence for each:
- [ ] Architecture modulaire et cohÃ©rente (Phase 1 audit confirms no drift)
- [ ] SÃ©curitÃ© complÃ¨te (RLS, JWT, RBAC, permissions, chiffrement) â cross-reference the prior
      Security Hardening phase, confirm nothing regressed
- [ ] ObservabilitÃ© et monitoring (Phase 2/5 Track A items live and proven)
- [ ] Logs et traÃ§abilitÃ© (Phase 10 Track A audit trail complete)
- [ ] Performance (requÃªtes SQL, Edge Functions, cache, index) â re-run Phase 8 hardening
      measurements, confirm no regression
- [ ] RÃ©silience (offline, reprise aprÃ¨s erreur, synchronisation) â re-run Phase 6 hardening
      offline integration tests
- [ ] ScalabilitÃ© (multi-salon, montÃ©e en charge) â note honestly that full load testing remains
      a post-V1.0 item per the existing roadmap; this checklist item is "architecturally ready,"
      not "load-tested at scale"
- [ ] MaintenabilitÃ© (documentation, conventions, diagrammes) â confirm
      `docs/DOCUMENTATION_INDEX.md` updated with every Phase 1-10 document from this pass
- [ ] Automatisation (CI/CD, workflows, backups) â cross-reference Phase 10 of the prior
      hardening pass, confirm still valid
- [ ] ConfigurabilitÃ© (Remote Config, Feature Flags, CMS) â Phases 3/4/8/9 proven live
- [ ] ConformitÃ© (prÃ©paration RGPD, audit, Data Safety) â Phase 10 Track A + Legal Center
      cross-referenced, contenu juridique final explicitly noted as **out of this prompt's
      scope** (business-owned, per the existing roadmap)
- [ ] QualitÃ© logicielle (0 `flutter analyze`, tests, couverture, non-rÃ©gression) â final full
      suite run, coverage % reported

**Livrable:** `docs/backend-completion/PHASE_11_BACKEND_COMPLETION_REPORT.md` â the honest
final verdict. If any item is not fully true, it must say so explicitly, not be marked done to
close the phase.

**Global Exit Criteria for the entire prompt:**
- [ ] Every Track A phase fully built, tested, and proven with evidence.
- [ ] Every Track B phase has its schema/engine ready but explicitly, visibly marked as
      "UI/analysis deferred to post-launch" â not silently incomplete, not accidentally built out
      further than scoped.
- [ ] `flutter analyze` = 0, full test suite green, count reported.
- [ ] One scoped commit per phase, final tag `git tag backend-complete-v1`.
- [ ] Updated `docs/DOCUMENTATION_INDEX.md` and `docs/PRODUCTION_CHECKLIST.md`.

After this tag, the only remaining KYNZA workstreams should be: UI Premium, final legal content,
marketing assets, Leapa go-live, Google Maps go-live, Play Store / App Store submission â exactly
as scoped, with Track B items (Business BI dashboards, live A/B experiments, financial/commission
audit reports) explicitly queued for immediately after V1.0 traction exists, not before.
