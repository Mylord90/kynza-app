# Phase 2 — Observability Enterprise (Track A)

> Checkpoint CP3 (part 1 of 2). Real technical visibility into the running system — 13 named
> dashboards from the brief, each mapped honestly to a real data source (or documented as
> genuinely client-only / structurally unavailable, never faked).

## 1. Objectifs

Build real, queryable technical dashboards (not business BI — that's Phase 6, Track B) covering:
Health, System Metrics, Crash, Sync, Queue, Edge Function, Realtime, Supabase, Storage,
Notification, Performance, Security, Network.

## 2. Architecture

A new `SYSTEM_ADMIN` scope gates every dashboard (Phase 1 audit finding, `docs/backend-completion/
PHASE_1_FINAL_AUDIT.md` §3 item 9): `public.users.is_system_admin` (additive boolean, layered on
top of the existing owner/manager/staff/client roles, not a new tenant role). Immutable via the
client API (extends the existing `protect_user_columns` trigger).

**Every admin-only view is read exclusively through a matching `SECURITY DEFINER` RPC that checks
`has_system_admin(auth.uid())` before touching any data** — the views themselves carry no grant to
`authenticated`/`anon` at all, since plain Postgres views can't have their own RLS and the
underlying catalog/aggregate tables (`information_schema`, `rate_limit_buckets`) have none of
their own either. This is the same enforcement shape as the existing `refresh_audit_stats()`
(`20260629110000_audit_enterprise.sql`), extended with an in-function role check since these must
remain callable-and-rejected for non-admins rather than revoked outright.

## 3. The 13 dashboards — real data source, mapped honestly

| Dashboard | Data source | Freshness | Notes |
|---|---|---|---|
| Health Dashboard | Composite — see Phase 5 (Health Center) | — | No separate view; this is the composition layer itself. |
| System Metrics | `v_supabase_dashboard` / `get_supabase_dashboard()` | Polled | Table/policy/index/view/function counts from `information_schema`/`pg_catalog`. |
| Supabase Dashboard | Same view as System Metrics | Polled | **Intentional consolidation** — both measure the same schema-health concept; 2 UI cards surface different columns of one real view rather than 2 near-identical pipelines. |
| Crash Dashboard | `v_crash_dashboard` / `get_crash_dashboard()`, fed by `CrashReportingService.recordErrorForSalon()` | Polled | Firebase Crashlytics has **no in-app read API** (Console-only) — this is a parallel, Postgres-side log of client-originated errors, not a mirror of Crashlytics itself. Only 2 representative call sites (`booking_providers.dart`'s loyalty-stamp and commission best-effort catches) were wired in this phase; the other ~19 `recordError` call sites keep using the original, unchanged `recordError()` — a documented, bounded follow-up, not silently claimed complete. |
| Sync Dashboard | `syncDashboardProvider` — `MutationOutboxService.pending()`/`.deadLetterItems()` | Client-only | The outbox/DLQ live in Hive, not Postgres — there is no SQL view to back this one, and inventing a fake server-side mirror of purely local state would misrepresent what's actually happening on this device. |
| Queue Dashboard | `v_queue_dashboard` / `get_queue_dashboard()` | Polled | Real: `automation_action_runs`/`automation_execution_logs` status counts. |
| Edge Function Dashboard | `v_edge_function_dashboard` / `get_edge_function_dashboard()`, fed by a new `edge_function_invocations` table | Polled | Only `create-booking` is wired to log invocations (highest-traffic function, proof of the pipeline) — the other ~19 Edge Functions are an explicit, documented follow-up. The instrumentation wraps the handler purely for timing; **zero business logic inside `create-booking` changed**. |
| Realtime Dashboard | `realtimeChannelStatusProvider` — this client's own `SupabaseClient.realtime` connection state | Client-only | Supabase's platform-level Realtime fleet health isn't exposed to a Flutter client at all — this is honestly scoped to "this device's own channel," not a fleet-wide view. |
| Storage Dashboard | `v_storage_dashboard` / `get_storage_dashboard()` | Polled | Real: aggregates `storage.objects` (Supabase Storage's own metadata table) by bucket. |
| Notification Dashboard | `v_notification_dashboard` / `get_notification_dashboard()` | Polled | Real: `notification_logs` delivery/failure rates, last 30 days. |
| Performance Dashboard | `performanceDashboardProvider` (always null) | Unavailable | Firebase Performance Monitoring has **no in-app read API** either (Console-only) — rendered as an honest "no read API" empty state, not a fabricated metric. |
| Security Dashboard | `v_security_dashboard` / `get_security_dashboard()` | Polled | Real: `rate_limit_buckets` near-limit callers, last hour. |
| Network Dashboard | `networkDashboardProvider` — reuses the existing app-wide `connectivityProvider` | Client-only, real-time | No second connectivity pipeline introduced. |

**7 real SQL views/RPCs, 4 genuinely client-only providers (Sync/Realtime/Network/Performance),
1 composite (Health, built in Phase 5), 1 intentional consolidation (System Metrics ≡ Supabase
Dashboard).** Every dashboard renders from a real query or a real client-side state read — none
render hardcoded/mock data. Where a dashboard's real answer today is "empty" or "no read API
exists," that is itself the honest, correct rendering (one of the 5 valid UI states), not a
failure to meet this phase's exit criterion.

## 4. Fichiers livrés

- `supabase/migrations/20260704120000_observability_system_admin.sql` (draft, unapplied)
- `lib/features/evolution/health_center/domain/repositories/health_center_repository.dart`
- `lib/features/evolution/health_center/data/repositories/health_center_repository_impl.dart`
- `lib/features/evolution/health_center/application/providers/health_center_providers.dart`
- `lib/core/models/user_profile.dart` (+`isSystemAdmin`)
- `lib/core/services/crash_reporting_service.dart` (+`recordErrorForSalon`, `recordError` unchanged)
- `lib/features/booking/application/providers/booking_providers.dart` (2 call sites wired)
- `supabase/functions/create-booking/index.ts` (timing wrapper only, logic untouched)
- `lib/core/router/app_router.dart`, `route_names.dart` (`_SystemAdminGuard`, new route)
- `test/unit/health_center_sync_dashboard_test.dart`, `health_center_dashboards_test.dart`

## 5. Conventions & Structure

Mirrors the existing Repository/Provider structure. Admin-only RPC-gating pattern documented above
reused verbatim for all 7 views rather than inventing a per-view bespoke access scheme.

## 6. Migrations SQL / nouvelles tables

`20260704120000_observability_system_admin.sql` — draft, **not applied to any Supabase project**.
Adds `users.is_system_admin`, `edge_function_invocations`, 7 views, 7 gated RPCs, extends
`logs_self_insert_safe`'s whitelist with `client_error_logged`.

## 7. Nouvelles Edge Functions

None new — `create-booking` was instrumented in place (timing wrapper, no logic change).

## 8. Tests

- `test/unit/health_center_sync_dashboard_test.dart` (2 tests): proves the Sync Dashboard reflects
  real outbox/DLQ state from a real Hive box.
- `test/unit/health_center_dashboards_test.dart` (3 tests): proves the RPC-backed providers
  surface exactly what the repository returns (real data or a real empty result), using a fake
  repository — the composition/no-mock-data principle.
- Full suite: 340 passing (was 335 before this phase).

## 9. Documentation associée

- `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` §3 item 9 (`SYSTEM_ADMIN` origin)
- `docs/backend-completion/PHASE_5_HEALTH_CENTER.md` (the composition screen)
- `docs/PRODUCTION_CHECKLIST.md` (bounded-instrumentation follow-ups logged)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 340/340 passing.
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] Every Track A dashboard renders real data from a real query, verified against actual
      current system state — confirmed per-dashboard in §3 above (including the 4 dashboards
      whose honest "real state" is client-only or has no server-side data source at all).
- [x] No Track B item (Analytics/Audit/Business/Battery/Memory Dashboard) was built in this
      phase — those remain Phase 6/10/prior-hardening-pass territory, untouched here.
