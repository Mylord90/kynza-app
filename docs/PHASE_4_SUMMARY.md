# PHASE 4 — Evolution Platform — Summary

## Scope
Three independent sub-systems added to the running app without touching any
existing route, screen, or migration. Each sub-system has its own feature
tree under `lib/features/evolution/`.

## What changed

### Migrations (3)

**`20260630110000_phase4_feature_flags.sql`**
- `feature_flags` table (global catalog): `key` UNIQUE, `is_enabled`,
  `rollout_percentage` 0–100. No authenticated INSERT — service_role only.
  Authenticated users read the catalog.
- `salon_feature_overrides` table: `(salon_id, flag_key)` UNIQUE. Owner ALL,
  manager SELECT via `has_role()`.
- `evaluate_feature_flag(p_key TEXT) → BOOLEAN` RPC: resolution order —
  1. Salon override → return `override.is_enabled`
  2. Global flag disabled → `false`
  3. `rollout_percentage ≥ 100` → `true`
  4. Deterministic bucket: `md5(salon_id || key) mod 100 < rollout_percentage`
  (masks MSB for positive result; returns `false` when `salon_id IS NULL`).
- 5 flags seeded: `instant_booking` ON globally; 4 others off or zero-rollout.

**`20260630110100_phase4_maintenance.sql`**
- `maintenance_windows` table: `(starts_at, ends_at, affects_all,
  affected_salon_ids UUID[])`. No authenticated INSERT. Authenticated SELECT.
- `is_maintenance_active() → TABLE(is_active, title, message, ends_at)` RPC:
  always returns exactly 1 row. Filters by `now() BETWEEN starts_at AND ends_at`
  + `affects_all = true OR salon_id = ANY(affected_salon_ids)`.
  Returns `{false, NULL, NULL, NULL}` when no active window.
  Guards against `auth.uid() IS NULL` (returns null from Flutter repo layer).

**`20260630110200_phase4_app_versions.sql`**
- `app_versions` table: `(platform CHECK IN ('android','ios'), version_name,
  version_code INT, is_minimum_required BOOL)`. UNIQUE `(platform, version_code)`.
- `check_app_version(p_platform, p_version_code) → TABLE(update_required,
  update_recommended, latest_version_name, latest_version_code, message)` RPC.
- Seeded: `('android','1.0.0',1,true)` + `('ios','1.0.0',1,true)` — matches
  `pubspec.yaml version: 1.0.0+1`.

### Flutter

**Constants:**
- `lib/core/constants/app_version.dart` — `kAppVersionCode = 1`,
  `kAppVersionName = '1.0.0'`, `kAppPlatform` (runtime: `Platform.isAndroid`),
  `kPlayStoreUrl` + `kAppStoreUrl` (placeholders until first store submission).
  Must be updated in sync with `pubspec.yaml` before each release.

**Models (Freezed + json_serializable):**
- `FeatureFlagModel`, `SalonFeatureOverrideModel`, `MaintenanceWindowModel`,
  `AppVersionCheckModel`

**Feature Flags** (`lib/features/evolution/feature_flags/`):
- `FeatureFlagRepositoryImpl`: `getFlags`, `evaluateFlag`, `getOverrides`,
  `setOverride` (upsert `on_conflict: salon_id,flag_key`), `removeOverride`
- `featureFlagsProvider`, `salonFeatureOverridesProvider(salonId)`,
  `FeatureFlagNotifier` (setOverride/removeOverride + invalidate)
- `FeatureFlagScreen`: lists all flags; per-tile Switch creates/updates override
  (shows effective value = override ?? global); X icon removes override;
  `_GlobalBadge` shows GLOBAL: ACTIVÉ / DÉSACTIVÉ / xx%.

**Maintenance** (`lib/features/evolution/maintenance/`):
- `MaintenanceRepositoryImpl.checkMaintenance()`: guards `auth.uid() == null`;
  calls `is_maintenance_active()` RPC; parses first row.
- `maintenanceStatusProvider` — non-autoDispose `FutureProvider`.
- `MaintenanceScreen`: `PopScope(canPop: false)`, `_EndsAtChip` shows formatted
  end time, `Timer.periodic(30s)` invalidates `maintenanceStatusProvider` so the
  router redirect re-evaluates and auto-navigates away when maintenance ends.

**Version Manager** (`lib/features/evolution/version_manager/`):
- `VersionRepositoryImpl.checkVersion()`: guards auth; calls `check_app_version`;
  passes `kAppPlatform` + `kAppVersionCode`.
- `appVersionCheckProvider` — non-autoDispose `FutureProvider`.
- `ForceUpdateScreen`: `PopScope(canPop: false)`, `_UpdateButton` calls
  `launchUrl(Platform.isAndroid ? kPlayStoreUrl : kAppStoreUrl,
  mode: LaunchMode.externalApplication)`, "Vérifier à nouveau" invalidates
  `appVersionCheckProvider`.

**Router changes** (`app_router.dart`):**
- `_AuthRefreshNotifier` now listens to 3 providers: `authNotifierProvider`,
  `maintenanceStatusProvider`, `appVersionCheckProvider`. Each change triggers
  GoRouter re-evaluation.
- Inside `authenticated` case, redirect chain (highest priority first):
  1. `update_required == true` AND path ≠ `/force-update` → `/force-update`
  2. `isActive == true` AND path ≠ `/maintenance` → `/maintenance`
  3. Otherwise `null` (no redirect)
- Routes added: `ownerFeatureFlags`, `maintenance`, `forceUpdate`.
- `_OwnerFeatureFlagsLoader` added (same pattern as other loaders).

**Settings:** "Drapeaux de fonctionnalités" tile added to `SettingsHomeScreen`.

## Verification
- `supabase db push` — 3 migrations applied cleanly.
- `feature_flags`: 5 rows, `instant_booking` enabled ✅
- `check_app_version('android', 1)`: `update_required=false` ✅
- `is_maintenance_active()`: `is_active=false` ✅
- `flutter analyze` → No issues found ✅
- `flutter test` → 164/164 passed ✅

## Remaining gaps
- `evaluate_feature_flag()` returns `false` when called with `service_role`
  (no salon_id in context) — expected behavior; function is for authenticated
  Flutter clients only.
- `kAppVersionCode = 1` is a hardcoded constant — must be updated with each
  release. A future `package_info_plus` integration would automate this but
  adds a build step dependency.
- Store URLs in `app_version.dart` are placeholders until first Play Store /
  App Store submission.
- Maintenance and version checks initialize as soon as the router is created
  (via `_AuthRefreshNotifier` subscriptions) — if the RPC fails (network error),
  the provider enters error state and the redirect fires `null` (no block),
  which is the safe/desired behavior.