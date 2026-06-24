# KYNZA — Phase 2.2 Summary

Notifications · Owner Dashboard Analytics · Advanced Availability Management

## 1. Files created

### Module 1 — Notifications
- `supabase/migrations/20260624060000_notifications_schema.sql` — `notification_templates`, `notification_logs`, `notification_preferences`
- `supabase/migrations/20260624061000_whatsapp_phone_column.sql` — `users.whatsapp_phone`/`whatsapp_opt_in`/`whatsapp_opt_in_at`
- `supabase/migrations/20260624062000_schedule_reminders_cron.sql` — hourly pg_cron → `schedule-reminders` via pg_net
- `supabase/functions/schedule-reminders/index.ts` — finds bookings landing in ~24h/~2h windows, idempotent
- `supabase/functions/_shared/whatsapp.ts` — WhatsApp Business Cloud API text sender
- `lib/core/models/notification_log_model.dart`, `notification_preferences_model.dart`, `notification_template_model.dart`
- `lib/features/notifications/**` — domain/data/application/presentation (repository, providers, 2 screens, 2 widgets)

### Module 2 — Dashboard analytics
- `supabase/migrations/20260624070000_analytics_views.sql` — `v_salon_kpis`, `v_top_services`, `v_top_staff`, `v_occupancy` (all `security_invoker = true`)
- `lib/core/enums/date_range.dart`
- `lib/core/models/analytics/salon_kpi_model.dart`, `top_service_model.dart`, `top_staff_model.dart`, `dashboard_summary_model.dart`
- `lib/core/utils/trend_calculator.dart` — pure period-over-period % change
- `lib/features/dashboard/**` — repository, providers, 5 widgets (KPI card, period selector, pure-`CustomPainter` bar chart, top services, top staff)

### Module 3 — Advanced availability
- `supabase/migrations/20260624080000_availability_advanced.sql` — `staff_working_hours`, `staff_breaks`, `availability_exceptions` + 2026 Burundi public-holiday seed
- `lib/core/services/timezone_service.dart` — Africa/Bujumbura (UTC+2, no DST) wall-clock ⇄ UTC
- `lib/core/models/staff_working_hour_model.dart`, `staff_break_model.dart`, `availability_exception_model.dart`
- `lib/features/availability/presentation/screens/salon_hours_screen.dart`, `staff_hours_screen.dart`, `breaks_management_screen.dart`, `exceptions_calendar_screen.dart`, `staff_picker_screen.dart`
- `lib/features/availability/presentation/widgets/staff_hours_editor.dart`, `break_editor_widget.dart`, `exception_form_widget.dart`, `exception_list_tile.dart`

### Tests
- `test/unit/notification_models_test.dart`, `analytics_test.dart`, `availability_models_test.dart`, `timezone_service_test.dart`

## 2. Files modified (additive, Phase 1/2 behavior preserved)

| File | Change | Why |
|---|---|---|
| `lib/core/router/route_names.dart` | +12 path constants | new screens need named, centralized routes |
| `lib/core/router/app_router.dart` | +9 routes, +4 deep-link loader widgets | notifications, dashboard reuse, advanced availability |
| `lib/core/services/availability_service.dart` | `getAvailableSlots` now consults exceptions → staff hours → salon hours (in that precedence) and folds staff breaks into the existing `occupied` list; added `isSalonOpen`/`hasConflict`; added Bujumbura-aware `_bujumburaWallClock` | extends rather than replaces — `combineDateAndTime`/`generateSlots`/`markRareIfFew` keep their exact tested contracts; the one real caller (`time_slot_screen.dart`) needed zero changes |
| `lib/features/availability/domain/repositories/availability_repository.dart` + `..._impl.dart` | +10 methods for staff hours/breaks/exceptions/holidays | new Module 3 data needs, on the existing repository rather than a parallel one |
| `lib/features/availability/application/providers/availability_providers.dart` | +5 providers, +6 `AvailabilityNotifier` methods | same notifier pattern as the existing `save`/`delete` |
| `lib/features/availability/presentation/screens/availability_management_screen.dart` | full rewrite into a navigation hub | the Phase 2 single-day override editor (week strip + blocked-slots) is unchanged in behavior, just relocated under "Jours bloqués (ponctuel)" — still fully reachable |
| `lib/features/home_owner/presentation/screens/home_owner_screen.dart` | Dashboard tab fully replaced with the Module 2 widgets; Calendar/Clients/Marketing/Profil tabs untouched | per spec "full replacement" of just the Dashboard tab |
| `lib/features/home_owner/presentation/widgets/kpi_card.dart`, `magic_cta_card.dart` | deleted | zero remaining references after the Dashboard tab rewrite (verified by grep before deleting) |
| `lib/features/home_client/presentation/screens/home_client_screen.dart`, `home_staff_screen.dart` | +notification bell / +availability icon in AppBar | Module 1.H / Module 3.H requirements |
| `lib/main.dart` | `TimeZoneService.init()` before Hive/Supabase init | Module 3.B requirement |
| `pubspec.yaml` | +`timezone: ^0.9.0` | Module 3.B |
| `supabase/functions/send-notification/index.ts` | rewritten: DB-driven templates (was hardcoded), preferences-aware, push **and** WhatsApp, logs one `notification_logs` row per channel attempted + one `in_app` row always | Module 1.D; the one existing caller (`leapa-webhook`, `{bookingId, event}`) needed no changes — the new payload shape is a superset |
| `supabase/functions/create-booking/index.ts` | +`booking_created` notification call (best-effort); +`checkAdvancedAvailability` (exceptions + breaks, Bujumbura-correct) before INSERT | Module 1.I / Module 3.I |
| `supabase/functions/accept-invitation/index.ts` | +`staff_joined` notification to the inviter | Module 1.I |

## 3. Migrations (all RLS-enabled, `has_role(auth.uid(), role, salon_id)` pattern matching the existing codebase)

| Table/View | RLS |
|---|---|
| `notification_templates` | public read (active, non-deleted) |
| `notification_logs` | own rows (select/update); owner/manager audit their salon's |
| `notification_preferences` | own row only |
| `staff_working_hours` / `staff_breaks` / `availability_exceptions` | owner/manager manage all in salon; staff manage their own; public read (non-deleted) |
| `v_salon_kpis` / `v_top_services` / `v_top_staff` / `v_occupancy` | `security_invoker = true` — inherit the underlying `bookings`/`staff_profiles` RLS, no privilege escalation |

## 4. Edge functions

| Function | Trigger | Purpose |
|---|---|---|
| `send-notification` (rewritten) | invoked by `leapa-webhook`, `create-booking`, `accept-invitation` | template lookup + interpolation, preference check, push + WhatsApp, logging |
| `schedule-reminders` (new) | pg_cron, hourly | fires `booking_reminder_24h`/`booking_reminder_2h` |
| `create-booking` (extended) | client | adds exception/break conflict checks + booking_created notification |
| `accept-invitation` (extended) | client | adds staff_joined notification |

## 5. Tests — 70 passing (17 new this phase)

Pure-logic only, matching this project's existing convention (no mocking package in `pubspec.yaml`; nothing here mocks Supabase). DB-dependent paths (exceptions/breaks affecting `getAvailableSlots`, `isSalonOpen`, `hasConflict`, the Edge Functions) are exercised by `flutter analyze` + manual review only — see Known Gaps.

## 6. Known gaps / deliberate scope trims

1. **Public-holiday backfill is one-time, 2026 only.** New salons created after this migration, or years beyond 2026, do not automatically get holiday rows — no trigger was added (not requested; would need a recurring-holiday calculation, not a static seed).
2. **`service_created` and `staff_invited` notification templates are seeded but unwired.** `staff_invited` has no `user_id` to notify (the invitee has no account yet); wiring `service_created` would mean notifying an Owner about their own action — low value, skipped.
3. **No DB-integration test harness.** `pubspec.yaml` has no mocking package; new repository/Edge Function logic is covered by `flutter analyze`/manual testing, not automated tests, consistent with the rest of the codebase (Phase 1/2 also has zero integration tests).
4. **Tapping a notification only marks it read.** No generic `/booking/:id` detail route exists in this app yet (only role-specific calendar tiles/sheets), so a deep navigation was not added rather than risk a dead link (R04).
5. **`ExceptionsCalendarScreen` is a sorted list, not a month-grid calendar.** Same CRUD functionality, fewer moving parts; matches the file name but not literally a calendar widget.
6. **`staff_breaks` recurring-only.** The schema has no date column for one-off (non-recurring) breaks, so `is_recurring` is currently informational only.
7. **`schedule-reminders` cron requires manual one-time Vault setup** (`project_url`, `service_role_key` secrets) — intentionally not in the migration, since that would mean committing a secret.

## 7. Build status

- `flutter analyze` — 0 issues
- `flutter test` — 70/70 passing
- `dart format` — applied only to files this phase touched (a whole-tree format run was reverted on Phase 1/2 files to avoid unrelated churn)
- `supabase db push` — all 5 migrations applied to project `hhdkjfpgaklhrhfoxlhj`
- `supabase functions deploy` — `send-notification`, `schedule-reminders`, `create-booking`, `accept-invitation` all deployed
- **Action required before the reminders cron actually fires**: create the two Vault secrets it reads (one-time, not committed — see migration 020's header comment):
  ```sql
  select vault.create_secret('https://hhdkjfpgaklhrhfoxlhj.supabase.co', 'project_url');
  select vault.create_secret('<service_role_key>', 'service_role_key');
  ```
- **Action required for WhatsApp sends**: set `WHATSAPP_TOKEN` and `WHATSAPP_PHONE_NUMBER_ID` Edge Function secrets (push-only until then; push itself requires `FCM_PROJECT_ID`/`FCM_SERVICE_ACCOUNT_JSON`, already a Phase 2 requirement).

## 8. Phase 3 preparation (unchanged from the original ask, not started)

- Loyalty program (`loyalty_cards`, stamps)
- Reviews & ratings (`reviews` table + moderation)
- Subscription billing (Pro/Premium via Leapa)
- Analytics export (PDF/CSV)
- `home_manager_screen` — still a placeholder
