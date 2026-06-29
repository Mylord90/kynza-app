# PHASE 1.1 — Enterprise RBAC — Summary

## Scope
Additive granular permission layer on top of the existing owner/manager/
staff/client role system (per `ENTERPRISE FOUNDATION V2` brief, sub-phase
1.1). Owner-managed permission groups, per-user overrides, a 15-minute
resolution cache (SQL + Hive), `PermissionGuard` for gating widgets, and
management screens reachable from the Owner's Profile tab.

The base prompt assumed `feature_flags`/`salon_settings`/`permission_groups`
already existed in migrations — they did not (grepped all 38 prior
migrations before writing anything). Built from scratch instead of
"extended."

## What changed

**New migrations:**
- `supabase/migrations/20260629100000_rbac_enterprise.sql` —
  `permission_definitions` (22 seeded), `permission_groups`,
  `permission_group_permissions`, `user_permission_groups`,
  `user_permission_overrides`, `user_effective_permissions_cache`,
  `check_permission()`, RLS on every table.
- `supabase/migrations/20260629100001_rbac_cache_invalidation.sql` —
  follow-up found while verifying: granting/revoking an override or group
  permission didn't take effect until the 15-min cache naturally expired.
  Added triggers that delete the affected cache rows immediately on write.

**Deviations from the brief (all deliberate, found while implementing):**
- `resource` is `NOT NULL DEFAULT ''` everywhere, not nullable. A nullable
  `resource` breaks `UNIQUE`/`ON CONFLICT` — Postgres treats every `NULL`
  as distinct, so the cache upsert would have inserted a new row per check
  instead of updating, and the catalog's dedup would silently stop working.
- `check_permission()` uses `has_role()`/a direct `salon_id` parameter
  guarded server-side, not `auth.jwt()->'app_metadata'->>'...'` — this
  project's real JWT hook (`custom_access_token_hook`) sets top-level
  `app_role`/`salon_id` claims and no RLS policy in this codebase reads
  `auth.jwt()` directly; every policy resolves role via `has_role()`
  against `public.users`. Matched that instead of the brief's assumed shape.
- Added an authorization guard inside `check_permission()`: an
  authenticated, non-owner/manager caller can only check their own
  permissions. The brief's version let any caller pass an arbitrary
  `p_user_id`/`p_salon_id`, which is an IDOR (any staff account could query
  any other user's permission flags). Verified the guard blocks cross-user
  probing and still lets owner/manager check a teammate's permissions.
- Dropped the brief's partial-index predicate (`WHERE expires_at > NOW()`)
  — Postgres rejects non-`IMMUTABLE` functions in index predicates; would
  have failed the migration outright.

**New Edge Function:**
- `supabase/functions/check-permissions/` — batch evaluation for screens
  that need many flags at once (e.g. a full permission matrix), rate
  limited 30/min/user. Uses the service-role client, which bypasses
  `check_permission()`'s own self-or-owner guard — re-enforces the same
  rule inside the function so a staff/client caller can't use the
  function's elevated key to probe another user's permissions.

**New Flutter — core:**
- `lib/core/models/permission_definition_model.dart`,
  `permission_group_model.dart`
- `lib/core/permissions/permission_cache.dart` — Hive TTL mirror of the SQL
  cache (new box, opened in `main.dart`)
- `lib/core/permissions/permission_service.dart` — `PermissionService`,
  `permissionProvider` (owner short-circuited client-side, same as the SQL
  bypass — pure UX optimization, not a security boundary)
- `lib/core/permissions/permission_guard.dart` — `PermissionGuard` widget

**New Flutter — feature (`lib/features/permissions/`):**
- `domain/repositories/permission_repository.dart`,
  `data/repositories/permission_repository_impl.dart`,
  `application/providers/permission_management_providers.dart`
- `presentation/screens/permission_groups_screen.dart`,
  `permission_group_detail_screen.dart` (permission toggles grouped by
  feature + member add/remove), `permission_group_form_sheet.dart`

**Routing/UI wiring:**
- `route_names.dart` — `ownerPermissionGroups`, `ownerPermissionGroupDetail`
- `app_router.dart` — both routes, owner-`_RoleGuard`-wrapped, salon-loader
  pattern matching `_OwnerAuditLogLoader`
- `home_owner_screen.dart` — "Permissions & Équipe" entry in the Profile
  tab (this app has no dedicated Settings screen yet — the Profile tab is
  the de-facto Settings home; Phase 1.4 will formalize this)

**Not changed (by design):** existing role checks (`UserRole.canViewWallet`
etc.), existing screens' access logic. RBAC is additive — nothing currently
shipped depends on permission groups yet. Per-user direct overrides
(`user_permission_overrides`) are schema-complete and enforced in
`check_permission()`, but there's no dedicated UI for managing them outside
of group membership — not in this sub-phase's acceptance criteria, deferred.
`permission_audit_screen` ("who has access to what") was in the brief's
architecture section but not its checklist — deferred for the same reason.

## Verification
- `check_permission()` tested directly against the remote DB inside a
  rolled-back transaction (6 scenarios: owner bypass, manager default-deny,
  staff default-deny, override flips to true with cache correctly
  invalidated, cross-user check blocked, manager-checks-staff allowed) —
  all passed, transaction rolled back, no permanent data touched.
- `PermissionGuard` covered by 3 widget tests
  (`test/unit/permission_guard_test.dart`): owner bypass without an RPC
  call, denied → fallback shown, granted → child shown.
- `flutter analyze` → No issues found.
- `flutter test` → 161/161 passed (158 prior + 3 new), 0 regressions.
- `dart format` → applied, no outstanding diffs.
- Not done: visual pass on an emulator/device (none available in this
  session, same constraint as Phase A) — flagging rather than claiming it.
- Edge Function deployed (`supabase functions deploy check-permissions`)
  but not exercised end-to-end over HTTP (no test client wired up); the
  underlying RPC it calls was verified directly.

## Remaining known gaps
- No dedicated UI for per-user permission overrides (group membership is
  the only UI-driven grant path for now).
- No "permission audit" screen (who has access to what across users).
- Permission groups UI lives under the Owner Profile tab, not a real
  Settings screen — will move once Phase 1.4 (Centre de Configuration)
  builds one.