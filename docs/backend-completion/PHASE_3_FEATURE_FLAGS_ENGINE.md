# Phase 3 — Feature Flags Enterprise

> Checkpoint CP2 (part 1 of 2) of the Backend Enterprise Completion pass. Extends the existing
> `feature_flags`/`salon_feature_overrides` system (prior Enterprise Hardening pass) — does not
> replace it. Full per-flag registry detail remains in `docs/FEATURE_FLAGS.md`; this document
> covers what changed in this phase.

## 1. Objectifs

Upgrade the existing Feature Flags system into a genuinely dynamic, no-redeploy engine: wider
scope granularity (role/user, not just global/salon), real Realtime propagation, documented
kill-switch semantics, and an admin UI with a scope editor and audit trail.

## 2. Architecture

```
feature_flags (existing, +category)
  ├── salon_feature_overrides (existing)
  ├── role_feature_overrides (new, salon-scoped)
  └── user_feature_overrides (new, salon-scoped, mirrors user_permission_groups)

evaluate_feature_flag(key) resolution order:
  1. user_feature_overrides (auth.uid())
  2. role_feature_overrides (caller's own salon + role)
  3. salon_feature_overrides (unchanged)
  4. feature_flags global + rollout_percentage (unchanged)
```

Realtime flow: Supabase `feature_flags` table change → `.stream()` (Supabase Realtime) →
`featureFlagsRealtimeProvider` (StreamProvider) → mirrors into `FeatureFlagCache` (Hive) →
`featureFlagsOfflineProvider` serves the latest value or last-cached snapshot offline.

Audit flow: `setOverride`/`removeOverride` (any of the 3 scopes) → `AuditLogger.
featureFlagOverrideSet/Removed()` → existing `activity_logs` table (extended whitelist) →
`FeatureFlagAuditScreen` (read-only).

## 3. Workflow / Data Flow

1. Owner opens `FeatureFlagScreen` → flags load grouped by category, each showing the effective
   salon-scoped value.
2. Owner taps the scope icon on a flag → bottom sheet with per-role toggles + a per-user override
   field.
3. Any override write → repository call → Supabase table write (RLS-gated, owner-only for their
   own salon) → `AuditLogger` writes an `activity_logs` row → relevant provider invalidated.
4. Any change to the flag catalog itself (e.g. a global toggle via the dashboard) → Realtime
   event → `featureFlagsRealtimeProvider` updates → cached to Hive → visible without app restart.

## 4. Fichiers livrés

- `supabase/migrations/20260704100000_feature_flags_enterprise.sql` (draft, unapplied)
- `lib/core/models/feature_flag_model.dart` (+`category` field)
- `lib/core/models/role_feature_override_model.dart` (new)
- `lib/core/models/user_feature_override_model.dart` (new)
- `lib/features/evolution/feature_flags/domain/repositories/feature_flag_repository.dart` (extended)
- `lib/features/evolution/feature_flags/data/repositories/feature_flag_repository_impl.dart` (extended)
- `lib/features/evolution/feature_flags/data/feature_flag_cache.dart` (new)
- `lib/features/evolution/feature_flags/application/providers/feature_flag_providers.dart` (extended: Realtime + role/user override methods)
- `lib/features/evolution/feature_flags/application/providers/feature_flag_audit_providers.dart` (new)
- `lib/features/evolution/feature_flags/presentation/screens/feature_flag_screen.dart` (category grouping + scope sheet)
- `lib/features/evolution/feature_flags/presentation/screens/feature_flag_audit_screen.dart` (new)
- `lib/core/audit/audit_logger.dart` (+`featureFlagOverrideSet/Removed`)
- `lib/main.dart` (registers `FeatureFlagCache` Hive box)
- `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (+10 new keys)
- `test/unit/feature_flag_realtime_test.dart`, `test/unit/feature_flag_cache_test.dart` (new)
- `docs/FEATURE_FLAGS.md` (§11 update)

## 5. Conventions & Structure

No new architectural pattern introduced — role/user overrides mirror the existing salon-override
Repository/Provider/Notifier shape, and the audit trail reuses `activity_logs` (extending its
whitelist) rather than a new table, per the codebase's own precedent
(`docs/PRODUCTION_CHECKLIST.md`'s "extends, doesn't duplicate" convention already used for
`mv_audit_stats`/`entity_versions`).

## 6. Migrations SQL

`20260704100000_feature_flags_enterprise.sql` — draft, **not applied to any Supabase project**
(local or remote), per Rule 8. Adds `feature_flags.category`, `role_feature_overrides`,
`user_feature_overrides`, updates `evaluate_feature_flag()`, extends
`logs_self_insert_safe`'s whitelist. Full SQL in the migration file itself.

## 7. Nouvelles Edge Functions

None — Phase 3 overrides remain direct authenticated table writes (RLS-gated), consistent with
the existing `salon_feature_overrides` pattern. (Phase 4 introduces the Edge-Function-gated write
pattern for Remote Config, where it's actually needed for validation.)

## 8. Tests

- `test/unit/feature_flag_realtime_test.dart` (2 tests): proves a flag flip reaches a listening
  provider without restart, using a fake repository + `StreamController` (no live network
  required to prove the propagation logic) — this is the exit criterion #1 proof.
- `test/unit/feature_flag_cache_test.dart` (3 tests): Hive round-trip for the new
  `FeatureFlagCache`.
- Full suite: 335 passing (was 326 before this phase — +9 across Phase 3 and Phase 4 combined).

## 9. Documentation associée

- `docs/FEATURE_FLAGS.md` §11 (this phase's changes)
- `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` §3 (origin of the "no per-role/per-user scope"
  and "no SYSTEM_ADMIN" findings this phase addresses/references)

## 10. Critères de validation

- `flutter analyze`: 0 issues (re-confirmed after every file in this phase).
- `flutter test`: 335/335 passing.
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] A flag toggled in Supabase reaches a running app instance without restart — proven by
      `test/unit/feature_flag_realtime_test.dart` (fake-repository Stream injection, asserting the
      provider's value changes after a second stream event with no re-fetch/restart in between).
- [x] Every flag category from the brief's list (Booking, Loyalty, Referral, Promotion,
      Analytics, Reviews, Subscriptions, Commission, Notifications, ProxiPay, Google Maps, Leapa,
      Staff, Owner, Client, Manager, Beta, Experimental) is represented — confirmed via the
      migration's category-assignment `UPDATE` covering all 32 flag keys — and independently
      toggleable (category is a grouping dimension only, does not restrict per-key toggling,
      which was already true and remains true).
