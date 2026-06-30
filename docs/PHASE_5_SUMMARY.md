# PHASE 5 — Documentation & Architecture — Summary

## Scope

Pure documentation phase. No migrations, no new Flutter code, no changes to
existing functionality. Goal: produce durable reference documents that a new
developer (or an AI agent in a fresh session) can use to understand the full
KYNZA Enterprise system without reading thousands of lines of code or migration
history.

## What was written

### `docs/PHASE_4_SUMMARY.md`
Detailed summary of the Evolution Platform built in Phase 4 (feature flags,
maintenance mode, version manager). Covers all 3 migrations, all Flutter
artifacts, router changes, verification checklist, and remaining gaps. Same
format as earlier phase summaries.

### `docs/ARCHITECTURE.md`
Comprehensive system architecture overview:
- System diagram (Flutter → Supabase → Leapa/FCM)
- Full tech stack table (Flutter 3.22, Riverpod 2.5, GoRouter 14, Freezed,
  Deno, fl_chart, Hive, Leapa, FCM, etc.)
- Flutter directory layout (core/ + features/ + shared/)
- Feature module 4-layer pattern (domain → data → application → presentation)
- Provider conventions (FutureProvider, FutureProvider.family, AsyncNotifier,
  autoDispose rules for router-read providers)
- 5-state UI machine (loading/error/empty/content-small/content-large)
- Database architecture: multi-tenancy, RLS policy pattern, soft-delete,
  auto-seed pattern (3 features using trigger + backfill), FTS tsvector
  columns, materialized view tenant isolation
- Edge Functions: shared helper pattern, function catalog table
- Auth & authorization flow (JWT → GoTrue → Postgres → has_role())
- Router architecture (no ShellRoute, _RoleGuard, loaders, _AuthRefreshNotifier,
  redirect priority chain)
- Booking creation data flow (end-to-end from Flutter tap to Realtime update)
- Offline strategy (ConnectivityService, Hive, KynzaOfflineBanner)
- Enterprise features table (Phases 1–4 summary)

### `docs/API_REFERENCE.md`
Catalog of all callable APIs:

**PostgreSQL RPCs (8):**
- `check_permission(resource, action) → BOOLEAN`
- `create_entity_version(type, id, data) → VOID`
- `search_salon_data(query, type?, province?, limit?) → TABLE`
- `render_template(template_id, variables) → TEXT`
- `create_default_document_templates(salon_id) → VOID`
- `evaluate_feature_flag(key) → BOOLEAN`
- `is_maintenance_active() → TABLE`
- `check_app_version(platform, version_code) → TABLE`

Each entry includes: auth requirement, params, return shape, behavior notes,
Dart snippet.

**Edge Functions (8):**
- `create-booking` (client → slot lock → Leapa → automation)
- `leapa-webhook` (HMAC auth → booking confirm/cancel)
- `mark-no-show` (staff → reliability score)
- `send-notification` (service_role → FCM)
- `validate-qr` (staff/owner → loyalty stamp → reward)
- `execute-workflow` (service_role → trigger evaluation → actions)
- `run-scheduled-actions` (pg_cron → retry queue → backoff)
- `create-backup` (owner/manager → 6h cooldown → storage JSON)

Each entry includes: auth mechanism, role requirement, request/response shape,
error codes.

**Key tables reference table** (16 rows, covering soft-delete columns and notes).

### `docs/SECURITY.md`
Full security model:
- Core principles (tenant isolation at DB, `has_role()` only, salon_id
  server-side, soft-delete, no service_role in Flutter)
- `has_role()` function full source + SECURITY INVOKER / STABLE explanation
- RLS policy patterns (read, write, owner-only, client-own-data)
- `check_permission()` resolution chain (user override → group → role defaults → deny)
- Edge Function auth pattern (JWT validate → role check → admin client)
- Freemium quota enforcement (in Edge Function, not Flutter — why it matters)
- Leapa webhook HMAC-SHA256 signature verification
- Secrets management table (Vault vs. code vs. committed)
- Role immutability RLS constraint (users.role can't change via authenticated client)
- Materialized view tenant isolation (MV no RLS → view with inline WHERE)
- Global tables (feature_flags, maintenance_windows, app_versions) write restriction
- Non-negotiable rules (verbatim, same as AGENT.md §2)

### `AGENT.md` updates
- Section 10: Added "Evolution Platform (Phase 4)" and "Documentation & Architecture
  (Phase 5)" paragraphs after the "Enterprise Data Platform (Phase 3)" block.
- Section 17 (DETTE TECHNIQUE): Added Phase 4 gaps entry (hardcoded
  `kAppVersionCode`, placeholder store URLs, `evaluate_feature_flag` service_role
  behavior, PopScope no bypass for Owner).

## Verification

```
flutter analyze → No issues found
flutter test → 164/164 passed (no tests written in this phase — all existing)
```

No migrations to push. No Flutter build required. All deliverables are
documentation files committed alongside the Phase 4 commit.

## Enterprise Foundation V2 — Complete

All 5 phases fully shipped:

| Phase | Name | Shipped |
|---|---|---|
| 1.1 | RBAC Enterprise | 2026-06-29 |
| 1.2 | Audit Enterprise | 2026-06-29 |
| 1.3 | Data Versioning | 2026-06-29 |
| 1.4 | Settings Center | 2026-06-29 |
| 2 | Automation Platform | 2026-06-30 |
| 3 | Enterprise Data Platform | 2026-06-30 |
| 4 | Evolution Platform | 2026-06-30 |
| **5** | **Documentation & Architecture** | **2026-06-30** |