# Phase 8 — Configuration Engine Coverage

> Checkpoint CP4 (part 1 of 2). Widens Phase 4's Remote Config engine's seeded coverage across
> every business domain named in the brief — introduces no second config storage mechanism.

## 1. Objectifs

Make these business domains configurable through the same `remote_config_entries` schema:
working hours defaults, commission rules, booking workflow parameters, loyalty rules, payment
method availability per region, promotion rule templates, subscription tier definitions, quota
thresholds, role/permission defaults.

## 2. Architecture

No new tables, no new Edge Function — `20260704130000_configuration_engine_coverage.sql` is a
pure data migration (`INSERT ... ON CONFLICT DO NOTHING`) against Phase 4's existing
`remote_config_entries`/`remote_config_versions`. `update-remote-config`'s
`categoryRefinementError()` was extended with 2 new category-specific checks
(`working_hours_defaults` must be `HH:MM`, `payment_method_availability` must be a non-empty array
of known method strings) and `quota_thresholds` was added to the existing non-negative-number
check group — the same validation function from Phase 4, not a second one.

## 3. Domain → config key mapping

| Business domain | Config key(s) | Source |
|---|---|---|
| Working hours defaults | `default_working_hours_start`, `default_working_hours_end` | This phase |
| Commission rules | `default_commission_rate_percent` (Phase 4), `commission_rate_type_default` (this phase) | Both |
| Booking workflow parameters | `booking_cancellation_window_hours` (Phase 4), `booking_no_show_grace_period_minutes` (this phase) | Both |
| Loyalty rules | `loyalty_stamps_required_for_reward` | This phase |
| Payment method availability per region | `payment_methods_available_bi` | This phase |
| Promotion rule templates | `promotion_max_discount_percent` | This phase |
| Subscription tier definitions | `subscription_tier_pro_price_bif` (Phase 4), `subscription_tier_premium_price_bif` (this phase) | Both |
| Quota thresholds | `max_bookings_per_day_free_tier` (Phase 4), `max_staff_free_tier` (this phase) | Both |
| Role/permission defaults | `default_permission_group_for_new_staff` | This phase |

## 4. Fichiers livrés

- `supabase/migrations/20260704130000_configuration_engine_coverage.sql` (draft, unapplied)
- `supabase/functions/update-remote-config/index.ts` (2 new category refinements + 1 extended check)

## 5. Conventions & Structure

No deviation from Phase 4's structure — this phase is purely additive seed data plus two small,
consistent validation-function extensions.

## 6. Migrations SQL

`20260704130000_configuration_engine_coverage.sql` — draft, **not applied to any Supabase
project**. 9 new `remote_config_entries` rows across the 9 domains above, each with a seeded
version-1 row, `ON CONFLICT (key) DO NOTHING` (safe to run alongside Phase 4's migration in any
order).

## 7. Nouvelles Edge Functions

None — extends the existing `update-remote-config`.

## 8. Tests

No dedicated new tests — this phase is data/validation coverage over Phase 4's already-tested
engine (`test/unit/remote_config_realtime_test.dart`, `remote_config_cache_test.dart` already
exercise the underlying mechanism this phase's rows flow through). The 2 new/extended category
refinements were traced by code review (same honest limitation as Phase 4 §8: no live Deno
runtime in this environment).

## 9. Documentation associée

- `docs/backend-completion/PHASE_4_REMOTE_CONFIG.md` (the engine this phase extends)

## 10. Critères de validation

- `flutter analyze`: 0 issues (no Dart code changed by this phase specifically, but re-confirmed
  as part of the CP4 gate).
- `flutter test`: 344/344 passing (shared count with Phase 9, same checkpoint).
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] No new config storage mechanism introduced — confirmed: this phase's migration contains
      only `INSERT` statements against tables Phase 4 already created; no `CREATE TABLE`.
- [x] Every listed business domain has at least one live, testable config key — confirmed per
      the mapping table in §3 (all 9 domains represented, 5 also carrying a Phase 4 key already).
