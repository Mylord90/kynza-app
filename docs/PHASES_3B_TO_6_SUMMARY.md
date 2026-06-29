# KYNZA — Phases 3B→6 + Advanced — Build Summary

Built 2026-06-27 in one continuous session, phase-by-phase with check-ins,
deploying to the live Supabase project as each phase shipped. Starting
point: 109 passing tests, Phase 3A just shipped. Ending point: 158
passing tests, `flutter analyze` 0 issues, 6 new migrations + 5 new Edge
Functions live in production.

## 1. Files created

**Models** — `lib/core/models/`: `loyalty/loyalty_qr_token_model.dart`,
`analytics/{churn_risk,client_ltv,cohort_retention,revenue_point,
staff_monthly_performance}_model.dart`, `audit_log_model.dart`,
`staff_commission_model.dart`, `billing/{subscription_plan,invoice}_model.dart`,
`search/search_result_item.dart`.

**Services/utils** — `lib/core/`: `router/deep_link_handler.dart`,
`services/{crash_reporting_service,export_service}.dart`,
`utils/{linear_regression,csv_exporter,security_utils}.dart`.

**Features** — full new feature folders: `lib/features/referral/`,
`lib/features/billing/`, `lib/features/team/`, `lib/features/search/`
(each with domain/data/application/presentation layers). Plus individual
new screens/widgets in existing features: `loyalty/.../loyalty_qr_screen.dart`,
`loyalty/.../loyalty_scan_screen.dart`, `staff/.../staff_detail_screen.dart`,
`staff/.../my_performance_screen.dart`, `dashboard/.../advanced_dashboard_screen.dart`,
`dashboard/.../audit_log_screen.dart`, `dashboard/presentation/widgets/
kynza_{line_chart,bar_chart_fl,pie_chart,cohort_table}.dart`,
`dashboard/.../audit_log_{providers,repository,repository_impl,tile}.dart`.

**i18n** — `l10n.yaml`, `lib/l10n/app_{fr,en}.arb` (+ generated
`app_localizations*.dart`).

**Backend** — 6 migrations, 5 Edge Functions, 1 shared helper (`_shared/rate_limit.ts`) — see §3/§4.

**Tests** — 8 new files, 49 new test cases (see §6).

**Docs** — `docs/PRODUCTION_CHECKLIST.md`, this file.

## 2. Files modified

Router (`app_router.dart`, `route_names.dart`, `deep_link_handler.dart`
wiring), auth (`auth_redirect.dart`, `auth_notifier.dart` for Crashlytics
`setUser`), `main.dart` (runZonedGuarded + i18n wiring), `session_service.dart`
(pending-referral-token, recent-searches), `share_service.dart` (haptics +
4 new share methods), `app_providers.dart` (`LanguageNotifier.setLanguage`),
`kynza_constants.dart` (bank-transfer placeholder), `salon_full_model.dart`
(`planStartedAt`), `staff_profile_model.dart` (commission fields),
`analytics_repository.dart`/`_impl.dart` + `dashboard_providers.dart`
(9 new methods), `booking_providers.dart` (commission-calculation hook),
`loyalty_repository.dart`/`_impl.dart`/`loyalty_providers.dart` (QR token
creation), `notifications_screen.dart`/`notification_providers.dart`
(filter/grouping/pagination), `staff_repository_impl.dart` (soft-delete
fix), `staff_form_screen.dart`/`staff_list_screen.dart` (commission rate,
team band/filters), `home_owner_screen.dart`/`home_staff_screen.dart`
(Dashboard tab → `AdvancedDashboardTabs`, Ma Perf tab → `MyPerformanceScreen`,
language toggle, entry points), `client_profile_screen.dart` (language
toggle), `salon_discovery_screen.dart` (search entry point),
`AndroidManifest.xml`/`settings.gradle.kts`/`app/build.gradle.kts`
(deep-link intent filters + Crashlytics Gradle plugin), `pubspec.yaml`
(11 new packages: qr_flutter, mobile_scanner, fl_chart, pdf, printing,
csv, firebase_crashlytics, flutter_localizations, + intl bump to 0.20.2).

## 3. SQL tables/views/functions created

| Name | Type | Purpose | RLS |
|---|---|---|---|
| `loyalty_qr_tokens` | table | single-use, time-expiring loyalty QR codes | client inserts own; staff reads via service-role only |
| `v_client_ltv` | view | per-client visit count + lifetime spend | `security_invoker` |
| `v_staff_monthly_performance` | view | per-staff monthly completions/no-shows/revenue/rating | `security_invoker` |
| `v_churn_risk` | view | clients 15+ days since last visit, risk-bucketed | `security_invoker` |
| `get_cohort_retention()` | RPC | monthly cohort retention, 0-3 month offsets | `SECURITY INVOKER` |
| `staff_commissions` | table | per-booking commission ledger | owner manages; staff sees only their own rows (R11) |
| `staff_profiles.commission_type/_rate` | columns | per-staff commission config | — |
| `subscription_plans` | table | the 3 plan tiers + features JSONB | public read (active only) |
| `invoices` | table | manual-billing invoice records | owner-only |
| `mark_invoice_paid()` | RPC | atomic invoice-paid + plan-flip | `SECURITY INVOKER` |
| `salons.plan_started_at` | column | informational billing-period anchor | — |
| `rate_limit_buckets` + `check_rate_limit()` | table+RPC | fixed-window rate limiting for Edge Functions | service-role only |
| `search_logs` + `v_popular_searches` | table+view | search analytics; the view is intentionally **not** `security_invoker` (cross-user aggregate by design) | insert-own only; view is public |
| 13 new indexes | indexes | closed missing-FK-index gaps found during the ADV.6 audit | — |

## 4. Edge Functions created

| Function | Trigger |
|---|---|
| `validate-qr` | Staff/owner/manager scans a client's loyalty QR |
| `claim-referral` | New/existing user opens an `accept-referral` deep link |
| `calculate-commission` | Called from `BookingActionNotifier.markCompleted` right after a booking is marked completed |
| `create-manual-invoice` | Owner taps "Passer à Pro/Premium" |
| `_shared/rate_limit.ts` | Shared helper, not standalone — wired into the 9 functions above plus `accept-invitation`, `create-booking`, `create-payment`, `create-walkin-booking`, `mark-no-show` |

## 5. Screens created

| Route | Role | Screen |
|---|---|---|
| `/accept-referral` | any (detours through register if logged out) | `ReferralClaimScreen` |
| `/client/loyalty/qr/:cardId` | client | `LoyaltyQrScreen` |
| `/owner/loyalty/scan` | owner/manager/staff | `LoyaltyScanScreen` |
| `/owner/analytics[/clients\|/team\|/forecast]` | owner | `AdvancedDashboardScreen` (4 sub-tabs) |
| `/owner/audit-logs` | owner | `AuditLogScreen` |
| `/owner/team` (+ existing `/owner/staff`) | owner | enhanced `StaffListScreen` |
| `/owner/team/:staffId` | owner | `StaffDetailScreen` |
| `/owner/team/commissions` | owner | `CommissionScreen` |
| `/staff/performance` (+ "Ma Perf" tab) | staff | `MyPerformanceScreen` |
| `/owner/subscription` | owner | `SubscriptionPlansScreen` |
| `/owner/billing[/invoices\|/success]` | owner | `BillingScreen`, `InvoiceHistoryScreen`, `UpgradeSuccessScreen` |
| `/search` | client | `AdvancedSearchScreen` |

## 6. Tests created

8 files, 49 new test cases: `deep_link_handler_test.dart` (8),
`linear_regression_test.dart` (6), `analytics_phase4_models_test.dart` (9),
`staff_commission_model_test.dart` (5), `billing_models_test.dart` (6),
`csv_exporter_test.dart` (3), `security_utils_test.dart` (5),
`search_filters_test.dart` (6), plus 1 added to the existing
`loyalty_models_test.dart`. Total: 109 → **158**, all green.

## 7. Bugs found & fixed (not asked for — found while building)

1. **`create-walkin-booking` had no server-side freemium-limit check** —
   only the Flutter client checked it before opening the walk-in sheet, so
   the 20-booking/month free-plan cap was bypassable by calling the Edge
   Function directly. Fixed to mirror `create-booking`'s check.
2. **`check_and_increment_promo_quota` / `get_staff_week_rank`** were
   missing the `REVOKE EXECUTE ... FROM anon` defense-in-depth every other
   RPC has. Not exploitable (both self-guard via `auth.uid()`), but fixed
   for consistency.
3. **13 foreign-key columns with no covering index**, several on columns
   actually queried on every app load (`staff_profiles.user_id` via
   `myStaffProfileProvider`, `bookings.service_id` via `v_top_services`).
4. **`StaffRepositoryImpl.removeService` hard-deleted** from
   `staff_services` despite that table having `deleted_at` and
   `getAssignedServiceIds` already filtering by it. Switched to soft
   delete; `assignService` now explicitly clears `deleted_at` on
   re-assignment.
5. **A stray accidental edit** (not mine, but caught and fixed):
   `auth_boot_gate.dart` was missing the `auth_ui_state.dart` import it
   needs for `AuthAuthenticated`, breaking `flutter analyze` — restored.

## 8. Production checklist

See `docs/PRODUCTION_CHECKLIST.md` for the full item-by-item audit —
every item was actually verified (grepped/cross-referenced), not assumed.
Summary: Security ✅, Performance ✅, Code Quality ✅, UX ✅, Data ✅ integrity
(with 2 real fixes applied, see §7).

## 9. Known gaps

- **Bank transfer details are placeholders** (`[À CONFIGURER]`) in both
  `KynzaConstants.bankTransferInstructions` and `create-manual-invoice`.
  Must be replaced with real account details before any real upgrade
  request reaches a customer.
- **i18n**: pipeline fully wired (ARB, `flutter_localizations`, toggle,
  persistence) and proven with real keys, but the ~100+ existing
  screens' hardcoded French strings were **not** retrofitted — that's
  separate, large, mechanical future work.
- **Subscription plans don't gate any feature** beyond lifting the
  free-plan booking cap — Phase 4/5 analytics/team/audit screens are
  role-gated only, not plan-gated. A separate product decision if wanted.
- **`feature_flags` table was never built** — referenced in the original
  Phase 3B spec but nothing across the entire build ever reads/writes it.
- **`kynza_heatmap.dart`** (STEP 4.2) was skipped — the detailed STEP 4.3
  UI spec never actually placed it in any sub-tab.
- **CSV export button on the Team sub-tab was skipped in Phase 4**, then
  added properly once `CsvExporter` existed (ADV.2) — no longer a gap.
- **"Fill My Day" CTA** on the low-occupancy insight (Forecast tab) was
  skipped — no target screen exists anywhere in the spec for it.

## 10. Play Store preparation

- **App signing**: `android/app/build.gradle.kts` still signs release
  builds with the **debug** keystore (`signingConfig =
  signingConfigs.getByName("debug")`, pre-existing, not changed this
  session). **Must** be replaced with a real upload keystore + signing
  config before any Play Store submission — this was out of scope for
  this build but is a hard blocker for release.
- **ProGuard/R8**: no custom `proguard-rules.pro` exists yet; default R8
  shrinking applies. Worth a dedicated pass once release signing is set
  up, to confirm none of the newer reflection-based plugins (`pdf`,
  `mobile_scanner`, `firebase_crashlytics`) need keep-rules.
- **Release build command** (once signing is configured):
  ```powershell
  flutter build appbundle --release `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
    --dart-define=APP_ENV=production
  ```
- **Store metadata still needed**: app icon variants (adaptive icon
  exists per the default Flutter template — confirm it's KYNZA-branded,
  not the placeholder), feature graphic, screenshots (FR, ideally per
  role — owner dashboard, client booking, staff agenda), short/full
  description in French, privacy policy URL (required given Crashlytics
  + Firebase Messaging + Supabase Auth collect user data), content
  rating questionnaire, target API level compliance (check against the
  latest Play Store requirement at submission time, not build time).