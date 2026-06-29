# PHASE 1.4 — Centre de Configuration — Summary

## Scope
`salon_settings` (table + auto-creation + RLS) and a real Settings home,
closing Phase 1's only remaining checklist item ("salon_settings créée
automatiquement à la création de salon") and the deferred TODO from
Phase 1.1/1.2: move "Permissions & Équipe" off the Owner's ad-hoc Profile
tab into an actual Settings screen.

## What changed

**Migrations:**
- `supabase/migrations/20260629130000_salon_settings.sql` — `salon_settings`
  (29 columns across booking/notifications/marketing/staff/loyalty/
  reviews/payments/timezone/advanced), owner+manager RLS (matches
  services/invoices), `create_default_salon_settings()` trigger on
  `salons` INSERT, **and a backfill INSERT for every salon that already
  existed** — the trigger alone only covers salons created from this
  migration forward; both real salons in the DB were confirmed missing a
  settings row before the backfill ran.
- `supabase/migrations/20260629130100_audit_whitelist_settings.sql` —
  adds `settings_changed` to the audit RLS whitelist (Phase 1.2 deferred
  this because `salon_settings` didn't exist yet; it does now).

**Deviation from the brief:** dropped `salon_settings.currency` — `salons`
already has a `NOT NULL currency` column (foundation migration). A second
column for the same fact would be a second source of truth with no rule
for which one wins if they ever diverged. Kept `timezone` (salons has
none).

**New Flutter:**
- `lib/core/models/salon_settings_model.dart` — one field per column.
  Found a real bug while writing the round-trip test: json_serializable's
  `field_rename: snake` codegen turns `notifReminderHoursBefore2` into
  `notif_reminder_hours_before2` (no underscore before a trailing digit),
  not the actual DB column `notif_reminder_hours_before_2` — silently
  wrong reads/writes for that one field. Fixed with an explicit
  `@JsonKey(name: ...)` override (plus the usual Freezed
  `invalid_annotation_target` false-positive, suppressed inline rather
  than project-wide).
- `lib/features/settings/` (domain/data/application/presentation) —
  repository + providers (`salonSettingsProvider`,
  `salonSettingsNotifierProvider.updateField()`, which calls the new
  `AuditLogger.settingsChanged()`).
- `lib/features/settings/presentation/widgets/setting_field.dart` — a
  declarative `SettingField` (key/label/type) per column, grouped into 8
  category lists. Avoids 8 near-duplicate screen files: one generic
  `SettingsCategoryScreen` renders whichever list it's given (`toJson()`
  on the model + `field.key` lookup — no per-field switch needed, thanks
  to the snake_case codegen).
- `SettingsHomeScreen` — the new `/owner/settings` destination: one tile
  per category plus "Permissions & Équipe" (moved here from the Profile
  tab, replaced there with a single "Paramètres" entry).
- Did **not** touch the existing `notification_settings_screen.dart` —
  confirmed it manages a different table (`notification_preferences`,
  per-USER opt-in: "does *this person* want push/WhatsApp/email"), not
  `salon_settings.notif_*` (salon-wide: "does *this salon* use this
  channel at all"). Labeled the new category "Notifications du salon" to
  keep the two visually distinct in the UI.

## Verification
- `flutter analyze` → No issues found.
- `flutter test` → 164/164 passed (162 prior + 2 new model tests), 0
  regressions.
- `dart format` → applied, no outstanding diffs.
- Backfill confirmed against the remote DB: both existing salons had a
  `salon_settings` row with correct defaults after the migration ran.
- Auto-creation trigger verified directly against the remote DB inside a
  rolled-back transaction: inserting a new salon produced a matching
  settings row with every default applied.
- Not done: visual pass on an emulator/device (none available this
  session, same constraint as every prior phase) — the bottom-sheet edit
  flow (tap a number/text row → sheet → save) hasn't been seen rendered.

## Remaining known gaps
- No PermissionGuard gating on the Settings screens themselves beyond the
  existing owner-only route guard — fine today since only Owner can reach
  `/owner/settings`, but if a future phase lets managers in too, the
  individual category screens have no finer-grained check.
- `SettingsCategoryScreen`'s integer/text edit flow has no input
  validation beyond `int.tryParse` falling back to the old value — e.g.
  nothing stops setting `booking_cancellation_hours` to a negative number.
- This closes Phase 1's combined checklist. Next is Phase 2 (Automation
  Platform — workflow engine) per the original brief, pending user
  check-in.