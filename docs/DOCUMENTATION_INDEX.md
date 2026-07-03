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
