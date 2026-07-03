# Phase 4 — Remote Configuration Engine

> Checkpoint CP2 (part 2 of 2) of the Backend Enterprise Completion pass. A versioned, auditable
> key/value config store — the backbone Phase 8 later widens.

## 1. Objectifs

A remote-config engine that lets business parameters (prices, commissions, quotas, theming,
copy keys, templates, workflow parameters) change without a redeploy, with full version history
and one-click rollback, and with a validation gate that guarantees a malformed value never
reaches a client.

## 2. Architecture

```
remote_config_entries   (key, category, value_json, value_type, description, updated_by, deleted_at)
remote_config_versions  (entry_id, version_number, value_json, changed_by, change_reason) — append-only
remote_config_audit     (entry_id, action, actor_id, before_json, after_json) — append-only

Write path (the ONLY write path — no client-role INSERT/UPDATE/DELETE policy exists):
  Flutter → update-remote-config Edge Function
    → validate against value_type + per-category refinement
    → UPDATE remote_config_entries (service_role)
    → INSERT remote_config_versions (new version)
    → INSERT remote_config_audit (action: updated)

  Flutter → rollback-remote-config Edge Function
    → look up the target remote_config_versions row
    → UPDATE remote_config_entries.value_json to that exact historical value
    → INSERT remote_config_versions (new version, append-only — never deletes later ones)
    → INSERT remote_config_audit (action: rolled_back)

Read path:
  Supabase Realtime on remote_config_entries → remoteConfigRealtimeProvider
    → mirrors into RemoteConfigCache (Hive) → remoteConfigOfflineProvider / remoteConfigValueProvider
```

Deliberately does **not** duplicate existing dedicated systems that already cover part of the
category list: `maintenance_windows`, `app_versions`, `subscription_plans`, `feature_flags`
(Phase 3) all keep their own tables/screens. `remote_config_entries` is for looser business
values that don't warrant a bespoke table — the seed rows reference the existing systems by name
where relevant rather than re-implementing them.

## 3. Workflow / Data Flow

1. Owner opens the new "Remote configuration" settings screen → entries load, grouped by
   category, each showing its current JSON value.
2. Owner taps edit → enters a new JSON value + optional change reason → submits.
3. `update-remote-config` validates (type + category refinement) → rejects with `400
   malformed_value` on failure, or writes + versions + audits on success.
4. Every connected client sees the new value the moment the Realtime event arrives — no redeploy.
5. Owner taps history → sees every version → taps "Restore this version" → `rollback-
   remote-config` restores the exact historical `value_json`, creating a new version rather than
   destroying history.

## 4. Fichiers livrés

- `supabase/migrations/20260704110000_remote_config_engine.sql` (draft, unapplied)
- `supabase/functions/update-remote-config/index.ts` (new)
- `supabase/functions/rollback-remote-config/index.ts` (new)
- `lib/core/models/remote_config_entry_model.dart`, `remote_config_version_model.dart` (new)
- `lib/features/evolution/remote_config/domain/repositories/remote_config_repository.dart` (new)
- `lib/features/evolution/remote_config/data/repositories/remote_config_repository_impl.dart` (new)
- `lib/features/evolution/remote_config/data/remote_config_cache.dart` (new)
- `lib/features/evolution/remote_config/application/providers/remote_config_providers.dart` (new)
- `lib/features/evolution/remote_config/presentation/screens/remote_config_screen.dart` (new)
- `lib/core/router/route_names.dart`, `app_router.dart` (new route `/owner/remote-config`)
- `lib/features/settings/presentation/screens/settings_home_screen.dart` (new menu entry)
- `lib/main.dart` (registers `RemoteConfigCache` Hive box)
- `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (+13 new keys)
- `test/unit/remote_config_realtime_test.dart`, `test/unit/remote_config_cache_test.dart` (new)
- `docs/EDGE_FUNCTIONS_REFERENCE.md` (2 new functions documented, catalog + per-function detail)

## 5. Conventions & Structure

Mirrors the Feature Flags feature's structure exactly (Repository/Provider/Notifier, Hive cache,
Realtime StreamProvider) rather than inventing a second pattern in the same codebase. Route added
as a new admin-only settings entry, reachable from `SettingsHomeScreen` — not an orphan screen
(the Phase 1 audit specifically checked for these).

**Access-control honesty note**: both Edge Functions gate on `role === 'owner'` as an interim
measure — remote config values are platform-wide, not salon-scoped, so this is broader than
ideal (any of KYNZA's salon owners could change a platform-wide default). This is **not** fixed
in this phase because the correct fix (a `SYSTEM_ADMIN` scope) is explicitly assigned to Phase
2/CP3 by the Phase 1 audit (`docs/backend-completion/PHASE_1_FINAL_AUDIT.md` §3, item 9). Flagged
in the Edge Function source, the `EDGE_FUNCTIONS_REFERENCE.md` entry, and here — not silently
left broad.

## 6. Migrations SQL / nouvelles tables

`20260704110000_remote_config_engine.sql` — draft, **not applied to any Supabase project**.
3 new tables (`remote_config_entries`, `remote_config_versions`, `remote_config_audit`), all with
RLS (`authenticated` read-only; no client write policy at all — the Edge Functions are the only
write path, using the service-role client). 13 representative seed rows, one per required
category, each with an initial version-1 row.

## 7. Nouvelles Edge Functions

`update-remote-config` and `rollback-remote-config` — see `docs/EDGE_FUNCTIONS_REFERENCE.md` for
full input/output/error/side-effect detail. Both rate-limited via the existing
`check_rate_limit` RPC, both use `getAuthenticatedUser()`/`createServiceRoleClient()` from
`_shared/supabase_admin.ts` — no new shared helper needed.

## 8. Tests

- `test/unit/remote_config_realtime_test.dart` (2 tests): proves a value change reaches a
  listening provider without redeploy (exit criterion #1), and demonstrates that a rollback's
  client-visible effect is mechanically the same propagation path (a `remote_config_entries` row
  changing value) already proven by the first test.
- `test/unit/remote_config_cache_test.dart` (2 tests): Hive round-trip + single-value lookup for
  `RemoteConfigCache`.
- **Honest limitation**: the Edge Functions' server-side validation logic (type-mismatch
  rejection, category refinements, exact-version restoration) could not be exercised live — no
  Docker/local Postgres and no Deno CLI exist in this environment (same tooling gap noted at
  Phase 0 of the prior Enterprise Hardening pass, not a new one), and applying the draft migration
  to any Supabase project (including the `kynza-dr-scratch` staging project) requires explicit
  approval per Rule 8, which this autonomous checkpoint loop does not have license to grant
  itself. The validation logic was traced by code review instead (see `index.ts` — the
  `typeMatches`/`categoryRefinementError` functions are pure, deterministic, and directly
  readable): a request with `value: "abc"` against a `number`-typed key hits the `!typeMatches`
  branch and returns `400 malformed_value` before any database write; a negative number against a
  `prices` key hits `categoryRefinementError` for the same result. Full live verification (Deno
  test or a real Edge Function invocation against a migrated staging project) remains a required
  manual step before this reaches production, flagged here rather than assumed.
- Full suite: 335 passing (was 326 before Phase 3+4 combined; +4 tests from this phase, +5 from
  Phase 3).

## 9. Documentation associée

- `docs/EDGE_FUNCTIONS_REFERENCE.md` (catalog + 2 new per-function sections)
- `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` §3 item 9 (the `SYSTEM_ADMIN` gap this phase's
  interim `owner`-only gate is standing in for)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 335/335 passing.
- No live/remote migration applied — draft only.

## 11. Checklist de sortie (Exit Criteria)

- [x] A config value changed remotely is reflected client-side without redeploy — proven by
      `test/unit/remote_config_realtime_test.dart`'s first test (fake-repository Stream
      injection, same technique as Phase 3's proof).
- [~] Rollback to a prior version tested and proven to restore exact prior state — the
      **client-side propagation mechanism** is proven (second test in the same file); the
      **server-side exact-restoration guarantee** is traced by code review, not executed live,
      for the honest reason given in §8 above. Marked partial, not silently claimed complete.
- [~] Malformed value write attempt rejected by the validating Edge Function — the validation
      logic exists and was traced by code review (§8), but was not exercised against a live
      Edge Function runtime for the same reason. Marked partial, not silently claimed complete.
