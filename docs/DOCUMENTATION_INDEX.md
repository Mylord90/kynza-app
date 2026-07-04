# KYNZA — Documentation Index

> Index of every document produced by the Enterprise Architecture & Documentation Expansion pass
> (14 parts, 2026-07-03). Grouped by Part number. This is a new file — no pre-existing `docs/`
> index was found to append to.
>
> For the narrative summary of what was built, what was flagged as tech debt, and what was
> intentionally left out of scope, see
> [`ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md`](ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md).

## Part 1 — Global System Architecture

- [`ARCHITECTURE_GLOBAL.md`](ARCHITECTURE_GLOBAL.md)
- [`diagrams/architecture-layers.mermaid`](diagrams/architecture-layers.mermaid)
- [`diagrams/dependency-diagram.mermaid`](diagrams/dependency-diagram.mermaid)
- [`diagrams/layer-diagram.mermaid`](diagrams/layer-diagram.mermaid)
- [`diagrams/communication-diagram.mermaid`](diagrams/communication-diagram.mermaid)
- [`diagrams/offline-diagram.mermaid`](diagrams/offline-diagram.mermaid)
- [`diagrams/realtime-diagram.mermaid`](diagrams/realtime-diagram.mermaid)
- [`diagrams/security-diagram.mermaid`](diagrams/security-diagram.mermaid)

## Part 2 — Complete Role-Based Workflows

- [`WORKFLOWS.md`](WORKFLOWS.md)
- [`diagrams/workflow-client.mermaid`](diagrams/workflow-client.mermaid)
- [`diagrams/workflow-owner.mermaid`](diagrams/workflow-owner.mermaid)
- [`diagrams/workflow-manager.mermaid`](diagrams/workflow-manager.mermaid)
- [`diagrams/workflow-staff.mermaid`](diagrams/workflow-staff.mermaid)
- [`diagrams/workflow-client_support.mermaid`](diagrams/workflow-client_support.mermaid) — role
  confirmed not implemented; diagram documents the gap, not a fabricated journey

## Part 3 — Database Architecture

- [`DATABASE_ARCHITECTURE.md`](DATABASE_ARCHITECTURE.md)
- [`diagrams/erd.mermaid`](diagrams/erd.mermaid)
- `../supabase/migrations/20260703120000_indexes_optimization.sql` — drafted, **not applied**

## Part 4 — Edge Functions Workflow Catalog

- [`EDGE_FUNCTIONS_REFERENCE.md`](EDGE_FUNCTIONS_REFERENCE.md)
- [`diagrams/edge-function-flow.mermaid`](diagrams/edge-function-flow.mermaid)

## Part 5 — Service Catalog (Taxonomy & Data Model)

- [`CATALOG_ARCHITECTURE.md`](CATALOG_ARCHITECTURE.md)
- [`CATALOG_EXTENSION_GUIDE.md`](CATALOG_EXTENSION_GUIDE.md)
- [`diagrams/catalog-erd.mermaid`](diagrams/catalog-erd.mermaid)
- `../supabase/migrations/20260703130000_catalog_schema.sql` — drafted, **not applied**
- `../supabase/seed/categories_seed.sql` — drafted, **not applied**, depends on the schema
  migration above

## Part 6 — Feature Flags Registry

- [`FEATURE_FLAGS.md`](FEATURE_FLAGS.md)
- `../supabase/migrations/20260703140000_feature_flags_registry.sql` — drafted, data-only,
  **not applied**

## Part 7 — External API Reference

- [`API_REFERENCE_ENTERPRISE.md`](API_REFERENCE_ENTERPRISE.md) — contains the AndroidManifest
  permissions critical finding

## Part 8 — Assets Architecture

- [`ASSETS_GUIDE.md`](ASSETS_GUIDE.md)
- 13 new folders under `../assets/` (structural, `.gitkeep` placeholders)
- `../pubspec.yaml` — 13 new asset path declarations

## Part 9 — Animations System

- [`ANIMATIONS_GUIDE.md`](ANIMATIONS_GUIDE.md)

## Part 10 — Design System Completion

- [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) — new file (didn't exist before this pass)

## Part 11 — Offline-First Strategy

- [`OFFLINE_STRATEGY.md`](OFFLINE_STRATEGY.md)

## Part 12 — Security Enterprise

- [`security/SECURITY_ENTERPRISE.md`](security/SECURITY_ENTERPRISE.md)
- [`SECURITY.md`](SECURITY.md) — extended in place (correction note appended, not rewritten)

## Part 13 — Performance Targets

- [`PERFORMANCE_TARGETS.md`](PERFORMANCE_TARGETS.md)

## Part 14 — Production Checklist (Extended)

- [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) — extended in place across 4 dated
  "Update" sections (one per phase of this pass) plus a final Part 14 section; original content
  and the 8 pre-existing tracked tech-debt items untouched

## Final wrap-up

- [`DOCUMENTATION_INDEX.md`](DOCUMENTATION_INDEX.md) (this file)
- [`ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md`](ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md)

## Pre-existing documents extended (not replaced) by this pass

| File | What changed |
|---|---|
| `ARCHITECTURE.md` | Untouched — `ARCHITECTURE_GLOBAL.md` is a separate, cross-linked companion |
| `API_REFERENCE.md` | Untouched — `EDGE_FUNCTIONS_REFERENCE.md` and `API_REFERENCE_ENTERPRISE.md` are separate, cross-linked companions |
| `SECURITY.md` | §4 correction note appended (Part 12) |
| `PRODUCTION_CHECKLIST.md` | 4 dated sections appended (Parts 3, 2/6/7, 11/12/13, 14) |

## Migrations drafted in this pass — apply status

| File | Status |
|---|---|
| `supabase/migrations/20260703120000_indexes_optimization.sql` | Drafted, not applied |
| `supabase/migrations/20260703130000_catalog_schema.sql` | Drafted, not applied |
| `supabase/seed/categories_seed.sql` | Drafted, not applied (depends on the above) |
| `supabase/migrations/20260703140000_feature_flags_registry.sql` | Drafted, not applied — flagged as lower-risk (data-only) than the other two, pending your decision |

None of these were run against the remote project (`hhdkjfpgaklhrhfoxlhj`) — this repo has no
local Supabase/Docker stack, so `supabase db push` always targets the live project directly, per
the decision made before this pass began.

## Enterprise Hardening & Production Readiness pass (Phases 0–11, 2026-07-03)

> A separate, later, sequential 12-phase pass — "feature-complete" to "release-safe." Full
> narrative: [`ENTERPRISE_HARDENING_REPORT.md`](ENTERPRISE_HARDENING_REPORT.md). Tagged
> `pre-hardening-baseline` (start) → `post-hardening-v1` (end).

- **Phase 0 — Baseline**: [`audit/PHASE_0_BASELINE.md`](audit/PHASE_0_BASELINE.md)
- **Phase 1 — Android Release Hardening**: [`audit/ANDROID_RELEASE_HARDENING_REPORT.md`](audit/ANDROID_RELEASE_HARDENING_REPORT.md)
- **Phase 2 — Schema Reconciliation**: [`audit/SCHEMA_RECONCILIATION_REPORT.md`](audit/SCHEMA_RECONCILIATION_REPORT.md) (+ `diagrams/erd.mermaid` corrected)
- **Phase 3 — Legal Center**: [`LEGAL_CENTER_ARCHITECTURE.md`](LEGAL_CENTER_ARCHITECTURE.md);
  `../supabase/migrations/20260703150000_legal_center.sql` — drafted, **not applied**
- **Phase 4 — Observability & DR**: [`OBSERVABILITY_MONITORING.md`](OBSERVABILITY_MONITORING.md),
  [`DISASTER_RECOVERY_RUNBOOK.md`](DISASTER_RECOVERY_RUNBOOK.md);
  `../supabase/migrations/20260703160000_health_dashboard_views.sql` — drafted, **not applied**
- **Phase 5 — Security Hardening**: [`security/SECURITY_AUDIT_V2.md`](security/SECURITY_AUDIT_V2.md)
- **Phase 6 — Offline-First Upgrade**: [`OFFLINE_STRATEGY.md`](OFFLINE_STRATEGY.md) — extensively
  rewritten in place (this file originated in the Documentation Expansion pass above, Part 11)
- **Phase 7 — Google Maps Scaffold**: [`GOOGLE_MAPS_ARCHITECTURE.md`](GOOGLE_MAPS_ARCHITECTURE.md)
- **Phase 8 — Accessibility & Performance**: [`audit/ACCESSIBILITY_PERFORMANCE_PASS.md`](audit/ACCESSIBILITY_PERFORMANCE_PASS.md)
- **Phase 9 — Testing Enterprise Expansion**: [`TESTING_ENTERPRISE_STRATEGY.md`](TESTING_ENTERPRISE_STRATEGY.md)
- **Phase 10 — Production Readiness**: [`PRODUCTION_READINESS.md`](PRODUCTION_READINESS.md),
  [`android/RELEASE_SIGNING_PROCEDURE.md`](android/RELEASE_SIGNING_PROCEDURE.md),
  [`security/APP_CHECK_ARCHITECTURE.md`](security/APP_CHECK_ARCHITECTURE.md),
  `../.github/workflows/ci.yml`
- **Phase 11 — Final Audit**: [`ENTERPRISE_HARDENING_REPORT.md`](ENTERPRISE_HARDENING_REPORT.md) (this pass's closing report)

### Pre-existing documents further extended by this pass

| File | What changed |
|---|---|
| `PRODUCTION_CHECKLIST.md` | A further "Phase 10" dated section appended (signing/R8/App-Check/CI-CD resolutions) |
| `SECURITY.md` | Corrected via Phase 5 findings (JWT storage was not actually Keychain-encrypted before this pass) |
| `OFFLINE_STRATEGY.md` | Rewritten to reflect the real Phase 6 outbox/DLQ architecture, superseding its Documentation-Expansion-pass content |

## Backend Enterprise Completion pass (Phases 1–11, 2026-07-04)

> A separate, later, 7-checkpoint pass — closes every remaining backend-infrastructure gap
> flagged at the end of the Enterprise Hardening pass above. Full narrative:
> [`backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md`](backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md).
> Tag: `backend-complete-v1`.

- **CP1 / Phase 1 — Final Audit**: [`backend-completion/PHASE_1_FINAL_AUDIT.md`](backend-completion/PHASE_1_FINAL_AUDIT.md), [`backend-completion/CHECKPOINT_1_REPORT.md`](backend-completion/CHECKPOINT_1_REPORT.md)
- **CP2 / Phase 3 — Feature Flags Engine**: [`backend-completion/PHASE_3_FEATURE_FLAGS_ENGINE.md`](backend-completion/PHASE_3_FEATURE_FLAGS_ENGINE.md);
  `../supabase/migrations/20260704100000_feature_flags_enterprise.sql` — drafted, **not applied**
- **CP2 / Phase 4 — Remote Configuration**: [`backend-completion/PHASE_4_REMOTE_CONFIG.md`](backend-completion/PHASE_4_REMOTE_CONFIG.md), [`backend-completion/CHECKPOINT_2_REPORT.md`](backend-completion/CHECKPOINT_2_REPORT.md);
  `../supabase/migrations/20260704110000_remote_config_engine.sql` — drafted, **not applied**;
  `../supabase/functions/update-remote-config/`, `../supabase/functions/rollback-remote-config/`
- **CP3 / Phase 2 — Observability Enterprise (Track A)**: [`backend-completion/PHASE_2_OBSERVABILITY.md`](backend-completion/PHASE_2_OBSERVABILITY.md);
  `../supabase/migrations/20260704120000_observability_system_admin.sql` — drafted, **not applied**
- **CP3 / Phase 5 — Health Center**: [`backend-completion/PHASE_5_HEALTH_CENTER.md`](backend-completion/PHASE_5_HEALTH_CENTER.md), [`backend-completion/CHECKPOINT_3_REPORT.md`](backend-completion/CHECKPOINT_3_REPORT.md)
- **CP4 / Phase 8 — Configuration Engine Coverage**: [`backend-completion/PHASE_8_CONFIGURATION_COVERAGE.md`](backend-completion/PHASE_8_CONFIGURATION_COVERAGE.md);
  `../supabase/migrations/20260704130000_configuration_engine_coverage.sql` — drafted, **not applied**
- **CP4 / Phase 9 — CMS Enterprise**: [`backend-completion/PHASE_9_CMS_ENTERPRISE.md`](backend-completion/PHASE_9_CMS_ENTERPRISE.md), [`backend-completion/CHECKPOINT_4_REPORT.md`](backend-completion/CHECKPOINT_4_REPORT.md);
  `../supabase/migrations/20260704140000_cms_enterprise.sql` — drafted, **not applied**
- **CP5 / Phase 6 — Business Observability (Track B, schema only)**: [`backend-completion/PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md`](backend-completion/PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md);
  `../supabase/migrations/20260704150000_business_observability_schema.sql` — drafted, **not applied**
- **CP5 / Phase 7 — A/B Testing Engine (Track B, engine only)**: [`backend-completion/PHASE_7_AB_TESTING_ENGINE.md`](backend-completion/PHASE_7_AB_TESTING_ENGINE.md), [`backend-completion/CHECKPOINT_5_REPORT.md`](backend-completion/CHECKPOINT_5_REPORT.md);
  `../supabase/migrations/20260704160000_ab_testing_engine.sql` — drafted, **not applied**
- **CP6 / Phase 10 — Audit Business**: [`backend-completion/PHASE_10_AUDIT_ENGINE.md`](backend-completion/PHASE_10_AUDIT_ENGINE.md), [`backend-completion/CHECKPOINT_6_REPORT.md`](backend-completion/CHECKPOINT_6_REPORT.md);
  `../supabase/migrations/20260704170000_audit_business.sql` — drafted, **not applied**
- **CP7 / Phase 11 — Backend Completion Checklist (final gate)**: [`backend-completion/PHASE_11_BACKEND_COMPLETION_REPORT.md`](backend-completion/PHASE_11_BACKEND_COMPLETION_REPORT.md), [`backend-completion/CHECKPOINT_7_REPORT.md`](backend-completion/CHECKPOINT_7_REPORT.md), [`backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md`](backend-completion/BACKEND_COMPLETION_FINAL_SUMMARY.md)

### New `SYSTEM_ADMIN` scope (introduced Phase 1/CP1, used throughout)

`public.users.is_system_admin` — additive, layered on top of existing owner/manager/staff/client
roles. Gates every admin-only dashboard/audit RPC introduced in this pass
(`has_system_admin(auth.uid())`). See `PHASE_1_FINAL_AUDIT.md` §3 item 9 for why it was needed.

### Pre-existing documents further extended by this pass

| File | What changed |
|---|---|
| `PRODUCTION_CHECKLIST.md` | 4 further dated sections appended (CP1, CP2/CP3, CP4, one per checkpoint with new gaps) |
| `EDGE_FUNCTIONS_REFERENCE.md` | 2 new functions documented (`update-remote-config`, `rollback-remote-config`) |
| `FEATURE_FLAGS.md` | §11 update — category/role/user overrides, Realtime propagation, audit trail |
| `DOCUMENTATION_INDEX.md` | This section |
