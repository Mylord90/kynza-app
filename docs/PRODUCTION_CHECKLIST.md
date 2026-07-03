# KYNZA — Production Readiness Checklist

Audited 2026-06-27 at the end of the Phases 3B→6 + Advanced build. Every
item below was actually verified against the codebase/migrations/deployed
state — not assumed. Where something needed a real fix, the fix shipped
as part of this audit (noted inline).

## Security

- [x] **All tables: RLS enabled + tested** — cross-referenced every
  `CREATE TABLE` against every `ENABLE ROW LEVEL SECURITY` across all
  migrations: 32/32 tables match, zero gaps.
- [x] **JWT hook: only injects safe claims** — `custom_access_token_hook`
  injects `app_role`, `salon_id`, `preferred_currency`, `country_code`
  only. `email`/`auth_provider` are read but deliberately never added to
  the claims.
- [x] **protect_user_columns: salon_id/role/email_verified protected** —
  also covers `reliability_score`; `role` has one narrow, intentional
  exception for the onboarding role-choice step.
- [x] **Edge Functions: HMAC validation on webhooks** — `leapa-webhook`
  verifies `x-leapa-signature` via `verifyLeapaSignature` before
  processing anything.
- [x] **No secrets in Flutter code** — `lib/core/constants/env.dart`
  loads everything via `String.fromEnvironment` (`--dart-define`), no
  hardcoded keys.
- [x] **Crashlytics initialized** — `CrashReportingService.init()` runs
  in `main()`, wrapped in `runZonedGuarded`; `setUser()` fires on every
  successful auth state transition.
- [x] **Rate limiting on Edge Functions** — `check_rate_limit` RPC +
  `rate_limit_buckets` table, wired into the 9 user-invoked authenticated
  functions (accept-invitation, create-booking, create-payment,
  create-walkin-booking, mark-no-show, validate-qr, claim-referral,
  calculate-commission, create-manual-invoice). Deliberately **not**
  applied to `schedule-reminders` (cron-only, no external caller),
  `send-notification` (internal service-to-service calls), or
  `leapa-webhook` (external payment webhook — already gated by HMAC,
  would need IP-based limiting instead, not the same caller-id shape).
- [x] **Found + fixed during this audit**: `create-walkin-booking` had no
  server-side freemium-limit check — only the Flutter client checked it
  before opening the sheet, so the limit was bypassable by calling the
  function directly. Now mirrors `create-booking`'s check.
- [x] **Found + fixed during this audit**: `check_and_increment_promo_quota`
  and `get_staff_week_rank` were missing the `REVOKE EXECUTE ... FROM
  anon` defense-in-depth every other RPC has (Postgres grants EXECUTE to
  PUBLIC by default). Both already self-guarded via `auth.uid()` checks
  so this wasn't exploitable, but it's now consistent.

## Performance

- [x] **ListView.builder for large/unbounded lists** — spot-checked the
  high-volume screens (notifications, audit log, search results,
  bookings, invoices): all use `ListView.builder`. Smaller bounded admin
  lists (team roster, filter chips, cohort table rows) use `Column` +
  `for` inside an outer scrollable, which is fine at this app's scale.
- [x] **const constructors** — enforced by the `prefer_const_constructors`
  lint; `flutter analyze` is 0 issues project-wide.
- [x] **No BackdropFilter/blur** — the only match for `BackdropFilter` in
  the codebase is the comment in `app_shadows.dart` documenting the rule
  itself; zero actual usage.
- [x] **Images: CachedNetworkImage** — `KynzaAvatar` (used for every
  user/staff/salon image across the app) wraps `CachedNetworkImage`
  internally; zero raw `Image.network` calls anywhere.
- [x] **Hive offline cache operational** — `SessionService` backs
  confidential mode, language, onboarding state, pending invitation/
  referral tokens, recent searches.
- [x] **Skeleton loaders on async screens** — `KynzaSkeleton` used
  pervasively across every `.when(loading: ...)` branch encountered
  during this build.

## Code Quality

- [x] **flutter analyze: 0 issues** — confirmed after every phase in this
  build, including this final pass.
- [x] **flutter test: 100% passing** — 158/158 (up from 109 at the start
  of this build — 49 new tests across Phases 3B→6 + Advanced).
- [x] **dart format: no changes** — confirmed clean.
- [x] **No critical TODOs** — only 2 `TODO` comments exist in the whole
  codebase, both intentional and tracked (see "Known gaps" below).
- [x] **No SalonYawe references** — zero matches.
- [x] **No hardcoded colors** — the only `Color(0x...)` literals outside
  `app_colors.dart`/`app_shadows.dart` are Google/Facebook's official
  OAuth brand colors in `kynza_oauth_button.dart`, which is correct (must
  match the provider's brand spec, not the app theme).
- [x] **All amounts: BIF only** — `€`/`$` only appear in
  `currency_code.dart`'s generic multi-currency enum (unused for display
  anywhere); every actual amount in the UI goes through
  `CurrencyFormatter`/`KynzaAmountWidget`, BIF-only.

## UX

- [x] **5 UI states** — the `KynzaSkeleton`/`KynzaErrorState`/
  `KynzaEmptyState`/data/offline-banner pattern is the default shape of
  every async screen built across this entire session.
- [x] **No dead-end screens** — `KynzaEmptyState` makes `ctaLabel`/`onCta`
  required at the type level; impossible to ship an empty state without one.
- [x] **All buttons: loading state** — `KynzaButton.isLoading` used on
  every async action across the new screens.
- [x] **Offline banner** — `KynzaOfflineBanner` present on every new
  screen with a network-dependent body.
- [x] **Confidential mode** — every monetary display in new code goes
  through `KynzaAmountWidget`, which already respects the global toggle.

## Data

- [x] **created_at + updated_at + deleted_at** — every table representing
  a mutable business entity has all three. The only tables without
  `deleted_at` are `loyalty_qr_tokens` (single-use, time-expiring —
  soft-delete doesn't apply), `notification_quota` and
  `rate_limit_buckets` (rolling-window counters), and `search_logs`
  (append-only log) — all correct by design, not gaps.
- [x] **No physical deletes** — **found + fixed during this audit**:
  `StaffRepositoryImpl.removeService` was hard-deleting from
  `staff_services` even though that table has `deleted_at` and
  `getAssignedServiceIds` already filtered by it. Now soft-deletes;
  `assignService` explicitly clears `deleted_at` on re-assignment so the
  upsert revives the same row correctly.
- [x] **Migrations: local == remote** — confirmed via
  `supabase migration list` after every single push this session, most
  recently just before writing this checklist.
- [x] **Soft-delete filtering** — `deleted_at IS NULL` (or
  `.isFilter('deleted_at', null)` client-side) is the consistent pattern
  across every repository touched this session.

## Known gaps (deliberately deferred, not oversights)

- **Bank transfer details are still `[À CONFIGURER]`** in both
  `KynzaConstants.bankTransferInstructions` and
  `create-manual-invoice/index.ts`. Must be replaced with KYNZA's real
  account details before any real upgrade request reaches a customer.
- **i18n**: the FR/EN pipeline (ARB files, `flutter_localizations`,
  language toggle, Hive persistence) is fully wired and proven with a
  couple of real keys (`authLogout` in both profile screens) — but the
  ~100+ existing screens' hardcoded French strings were **not**
  retrofitted to use `AppLocalizations`. That's a large, separate,
  mechanical effort with real regression risk if rushed; doing it
  properly is future work, not part of this pass.
- **Subscription plans don't gate any feature yet** — Pro/Premium
  currently only lift the free-plan booking cap. None of the Phase 4/5
  analytics, team, or audit-log screens are plan-gated (role-gated only).
  If real feature-gating by plan is wanted, that's a separate product
  decision.
- **`feature_flags` table was never built** — referenced in the original
  Phase 3B spec but nothing across Phases 3B→6 + Advanced ever actually
  reads or writes it.

## Update — 2026-07-03 (Enterprise Architecture & Documentation Expansion, Parts 1/3/4)

Two claims above are now stale and are corrected here rather than edited in place, per the
additive-only rule for this pass:

- **"32/32 tables match RLS" is superseded.** The schema has grown since 2026-06-27 through the
  RBAC, audit, entity-versioning, automation, data-platform, and evolution-platform phases. A
  full re-audit against all 58 migration files (`docs/DATABASE_ARCHITECTURE.md`) found **55
  tables, all 55 with RLS enabled — still zero gaps**, just a higher accurate count.
- **"`feature_flags` table was never built" is superseded.** It was built in
  `20260630110000_phase4_feature_flags.sql` and is seeded with 5 flags (`advanced_analytics`,
  `ai_scheduling`, `multi_location`, `client_app_v2`, `instant_booking`). See
  `docs/FEATURE_FLAGS.md` (Phase C).

New tech-debt items found during the Part 3 database audit (`docs/DATABASE_ARCHITECTURE.md` §4):

- [ ] **`salon_settings` and `owner_journey_progress` have no `deleted_at`** — both are 1:1-with-
  salon tables, inconsistent with every other "core" salon table's soft-delete convention.
- [ ] **`referrals` has no `deleted_at`** — the only loyalty/marketing table without one; no way
  to soft-delete a stale/spam referral today.
- [ ] **`salon_settings`, `permission_groups`, `automation_workflows` have an `updated_at` column
  but no trigger to maintain it** — a real correctness bug (silently stale timestamp), not a
  design choice.
- [ ] **Missing index on `salon_id` FK**: `staff_services`, `staff_working_hours`,
  `staff_breaks`, `automation_action_runs`, `notification_logs`. Draft fix (not applied):
  `supabase/migrations/20260703120000_indexes_optimization.sql`.
- [ ] **`salons.owner_id` is not a declared FK and has no index**, despite being used throughout
  RLS/insert checks.
- [ ] **`check-subscription` does not exist** (Edge Function, RPC, or cron) — a paid plan that
  lapses is never automatically reverted to `free`. The `subscription.expiring` automation
  trigger type is seeded with `wired: FALSE` for exactly this reason. See
  `docs/EDGE_FUNCTIONS_REFERENCE.md` §4.
- [ ] **`proxipay-create-session` has no unique constraint against `booking_id`** — multiple
  concurrent ProxiPay sessions can be created for the same booking.
- [ ] **No Edge Function sets an explicit timeout** — all 18 functions rely on the Supabase Edge
  Function platform default; no function-specific timeout budget is configured anywhere.
- [ ] **`docs/ai/skills/kynza-offline-realtime.md` describes an unbuilt target architecture** —
  the outbox queue, `OutboxSyncService`, `ConflictResolver`, and encrypted agenda/clients caches
  it specifies do not exist in `lib/`. Current offline support is limited to two unencrypted Hive
  boxes (session prefs, permission cache). See `docs/OFFLINE_STRATEGY.md` (Phase E) for the full
  gap analysis.

## Update — 2026-07-03 (Enterprise Architecture & Documentation Expansion, Parts 2/6/7)

New tech-debt items found during the Part 2 (workflows) and Part 6/7 (feature flags, external
APIs) audits:

- [ ] **🔴 CANDIDATE RELEASE-BLOCKER: `android/app/src/main/AndroidManifest.xml` (the release
  manifest) declares zero `<uses-permission>` entries, including `INTERNET`.** `INTERNET` is
  present only in `android/app/src/debug/AndroidManifest.xml` and `.../profile/AndroidManifest.xml`
  (Flutter's default dev-tooling template, not meant for the app's own network calls). A release
  build may have no network access at all. Not confirmed against an actual merged/built manifest
  in this pass — recommend running `flutter build apk --release` and inspecting the merged
  manifest before the next Play Store submission. See `docs/API_REFERENCE_ENTERPRISE.md`.
- [ ] **Camera/Photo-library permissions missing on both platforms** — `image_picker` and
  `mobile_scanner` are real, used dependencies (ProxiPay scan, loyalty scan, avatar/salon photo
  upload) but neither `AndroidManifest.xml` nor `Info.plist` declares `CAMERA`,
  `READ_MEDIA_IMAGES`, `NSCameraUsageDescription`, or `NSPhotoLibraryUsageDescription`. No
  `permission_handler` package exists either. iOS will hard-crash the process on first camera/
  photo-library access without the `Info.plist` keys.
- [ ] **iOS deep links likely unwired** — `Info.plist` has no `CFBundleURLSchemes` entry for
  `com.kynza.app://`, while Android's intent-filters for the same 4 hosts are confirmed present
  and correct. Unconfirmed without an iOS device test.
- [ ] **`PermissionGuard` (RBAC fine-grained gating) is built but wired into zero screens** — all
  current access control is coarse role-level (`_RoleGuard`) and RLS; the permission-groups
  system exists at the DB/service layer only. See `docs/WORKFLOWS.md` §2.5.
- [ ] **Manager home shell is a UI stub** — same 5-tab nav as Owner, all 5 tab bodies render the
  same static `KynzaEmptyState` regardless of selection. See `docs/WORKFLOWS.md` §3.3.
- [ ] **CLIENT_SUPPORT role does not exist at any layer** (enum, router guard, or
  `permission_groups.base_role` CHECK) — flagged as unbuilt, not invented. See
  `docs/WORKFLOWS.md` §3.5.
- [ ] **`feature_flags`/`evaluate_feature_flag()` exist and are functional but are called from
  nowhere in the app besides their own admin screen** — toggling any flag today has zero
  observable effect on any other screen. See `docs/FEATURE_FLAGS.md`.
- [ ] **`leapa_enabled` (referenced in the original roadmap as "the Leapa go-live switch") does
  not exist as a flag** — Leapa is unconditionally live via Vault secret presence, not gated by
  any flag. See `docs/FEATURE_FLAGS.md`.
- [ ] **Facebook and Apple sign-in are both stubs** (`throw UnimplementedError`), buttons
  disabled behind a "coming soon" tooltip. Only email/password and Google are real.
- [ ] **No Google Maps/Places/Directions/Geocoding/Geolocation, no Firebase Analytics, no local-
  notifications package** — none of these integrations named in the original roadmap have any
  matching dependency or code. See `docs/API_REFERENCE_ENTERPRISE.md` for the full per-API status
  table.
- [ ] **`route_names.dart`'s `clientBookingConfirm` constant has no matching `GoRoute`** — reached
  only via in-flow `Navigator.push`, not `context.go`. Low risk, but a stale/misleading constant.

## Update — 2026-07-03 (Enterprise Architecture & Documentation Expansion, Parts 11/12/13)

- [ ] **No offline outbox/local-cache system exists** — only two unencrypted Hive boxes (session
  prefs, permission cache). Every mutating flow (booking status change, cash payment, review,
  profile edit) requires network today; a cold start offline has no cached data to render for any
  `.stream()`-backed screen. See `docs/OFFLINE_STRATEGY.md` for the full per-flow gap table.
- [ ] **Both Hive boxes are unencrypted** (no `HiveAesCipher` anywhere in the codebase) — low
  current risk (no payment/password data cached), but inconsistent with the offline target spec.
  See `docs/security/SECURITY_ENTERPRISE.md` (OWASP M9).
- [ ] **No CI/CD pipeline exists at all** — no `.github/` workflows, no automated test/lint/
  dependency-scan gate on any branch. Blocks OWASP M2 (supply chain) mitigation and any future
  automated performance regression testing (Part 13).
- [ ] **No certificate pinning, no biometric auth, no root/jailbreak detection** — none
  implemented, none partially started. See `docs/security/SECURITY_ENTERPRISE.md` §3 for
  priority/roadmap notes on each.
- [ ] **`docs/SECURITY.md` §4 "Permission resolution chain" described a schema that doesn't match
  the real deployed `check_permission()` function** — corrected via an appended note in that file
  rather than an in-place rewrite; the real schema is junction-table-based
  (`permission_definitions`/`permission_groups`/`user_permission_groups`/
  `user_permission_overrides`), not a JSONB column on `users`.
- [ ] **No performance profiling has ever been run against a real target device** — every numeric
  target in `docs/PERFORMANCE_TARGETS.md` is a goal, not a measured baseline; no
  `firebase_performance` package exists to even start collecting real data.
- [ ] **`proxipay-confirm`'s 3G round-trip and every other Edge Function have no explicit timeout
  configured** (restated from the Part 4 finding) — directly blocks being able to guarantee the
  "<3s ProxiPay confirm" performance target.

## Part 14 — Extended Production Checklist (2026-07-03)

### Google Play

- [ ] **Store listing** — not started. `kPlayStoreUrl` in `lib/core/constants/app_version.dart`
  points to `com.kynza.app` (real package id, confirms the app identity is decided), but no
  listing copy, screenshots, or feature graphic exist in this repo (none would — they're
  Play Console assets, not app assets — flagged as a checklist item to produce, not a code gap).
- [ ] **Data Safety form** — must map to data *actually* collected, verified against real schema:
  personal info (name, phone, email — `users` table), location (**none collected** — no
  geolocation package exists, `docs/API_REFERENCE_ENTERPRISE.md`), photos (`salon_media`,
  `review_media`, avatars via `image_picker` — collected), financial info (`transactions`,
  `invoices` — collected, but KYNZA is explicitly non-custodial per R01, money never touches
  KYNZA's own accounts, only transaction *records*), app activity (`activity_logs`,
  `search_logs` — collected). This form must be filled out in Play Console directly; this
  checklist item is to ensure whoever fills it has the real, verified data inventory above rather
  than guessing.
- [ ] **Screenshots spec** — not produced (design-asset task, outside this doc pass's scope).
- [ ] **Feature graphic spec** — not produced (same).
- [ ] **Release notes template** — not established; recommend a simple `FR: ... / EN: ...`
  two-line format per release, stored wherever release notes are currently drafted (not found in
  this repo).
- [ ] **Versioning scheme** — confirmed real and consistent: `pubspec.yaml` `version: 1.0.0+1`
  matches `lib/core/constants/app_version.dart`'s `kAppVersionCode`/`kAppVersionName` (both must
  be updated together per that file's own comment) and is checked server-side against the real
  `app_versions` table via `check_app_version()` RPC (`docs/DATABASE_ARCHITECTURE.md` §3.10) for
  the force-update gate. `MAJOR.MINOR.PATCH+build` scheme already in use — no change needed.

### App Store (iOS — Phase 8, not blocking current Play Store push)

- [ ] **`kAppStoreUrl` is a literal placeholder** (`id000000000`) — confirms iOS submission
  hasn't started, consistent with `docs/CATALOG_ARCHITECTURE.md`/roadmap references to "Phase 8."
- [ ] **`Info.plist` gaps found in this pass are iOS-submission-blocking regardless of Phase 8
  timing**: missing `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` (would fail App
  Store review, not just crash at runtime — Apple explicitly rejects apps using camera/photo APIs
  without these keys) and missing `CFBundleURLSchemes` for the `com.kynza.app://` deep link
  scheme. See `docs/API_REFERENCE_ENTERPRISE.md`.

### Privacy Policy & Terms

- [ ] **Status: MISSING.** No privacy policy or terms-of-service file/screen found anywhere in
  this repo (checked for common filenames and a `help_center`/`support`/`legal` screen — none
  exist). This is a hard Play Store *and* App Store submission requirement (a live URL is
  mandatory in both consoles) — flagged as the single most concrete pre-launch blocker found in
  this entire documentation pass, alongside the AndroidManifest permissions gap (Part 7).

### Monitoring

- [ ] **Crashlytics**: real and initialized (`CrashReportingService.init()`, `runZonedGuarded` in
  `main()`, confirmed `docs/PRODUCTION_CHECKLIST.md`'s original audit). **No alert thresholds
  configured** — that's a Firebase Console setting, not code; recommend setting a crash-free-users
  threshold alert (e.g. <99%) once real user volume exists.
- [ ] **No Firebase Performance Monitoring** — package absent (Part 13 finding); would be the
  natural companion to Crashlytics for the numeric targets in `docs/PERFORMANCE_TARGETS.md`.

### Analytics

- [ ] **No Firebase Analytics / event-taxonomy system exists** (`docs/API_REFERENCE_ENTERPRISE.md`)
  — "event taxonomy completeness" cannot be checked because there is no event taxonomy. The
  in-house `analytics_views`/`mv_daily_revenue` SQL views power the owner dashboard, which is a
  different, business-metrics system, not a product/engagement analytics pipeline.

### Backup / Rollback Procedure

- [ ] **Real, implemented, verified**: `create-backup` Edge Function (owner/manager-triggered,
  max 1/6h cooldown) exports `salons`/`services`/`staff_profiles`/deduplicated clients/`bookings`
  (90-day lookback)/`reviews`/`invoices` (90-day lookback) to the `kynza-backups` Storage bucket,
  tracked in `backup_jobs` (`docs/EDGE_FUNCTIONS_REFERENCE.md` §5, `docs/DATABASE_ARCHITECTURE.md`
  §3.10). **Gap**: this is an *export*, not a *restore* mechanism — no code path reads a
  `backup_jobs` artifact back into the database. "Rollback procedure" as commonly understood
  (restore-from-backup) does not exist; only data export does.
- [ ] **Database-level rollback**: relies entirely on Supabase's platform-level point-in-time
  recovery (a paid-tier Supabase feature, not independently configured or verified from this
  repo) — not a KYNZA-authored capability.

### Support Process

- [ ] **No formal support process or CLIENT_SUPPORT role exists** (`docs/WORKFLOWS.md` §3.5,
  restated here since Part 14 explicitly asks "who handles CLIENT_SUPPORT escalations"). Today,
  by process of elimination from what's actually built, an owner is the only role with audit-log
  visibility (`ownerAuditLogs` route) — any client-facing support today would have to happen
  entirely outside the app (phone, WhatsApp, in-person), since no in-app help/contact/ticketing
  screen exists.

### Maintenance Mode Procedure

- [ ] **Real, implemented, verified**: `maintenance_windows` table + `is_maintenance_active()` RPC
  + the router's maintenance gate (`docs/WORKFLOWS.md` §2.3) — a window is created (service-role
  only, no in-app UI to create one), and every authenticated user is redirected to
  `MaintenanceScreen` while a window is active; `MaintenanceScreen` polls every 30s and
  self-clears on window end. **Gap**: no in-app or admin-tool UI exists to *create* a maintenance
  window — it must be inserted directly via Supabase Studio/SQL today.

### Known tech-debt items — full running list (all phases of this documentation pass)

Every `[ ]` item across the three "Update — 2026-07-03" sections above (Parts 3, 2/6/7, 11/12/13)
plus this Part 14 section is carried forward as open, unresolved tech debt — none were fixed as
part of this documentation-only pass, per its additive-only scope. The original 8 pre-existing
tracked items (bank transfer placeholder, i18n retrofit, plan-gating, etc., "Known gaps" section
above) remain open and unchanged.

## Update — 2026-07-03 (Phase 10, Enterprise Hardening pass — Production Readiness)

Unlike the documentation-only passes above, this update reflects items **actually fixed**, not
just newly documented. Full detail: `docs/PRODUCTION_READINESS.md`.

- [x] **Release signing** — the "release signs with the debug keystore" gap (flagged at Phase 0
  baseline of this hardening pass) is resolved: `android/app/build.gradle.kts` now conditionally
  loads a real keystore from `android/key.properties` (git-ignored) and falls back to debug
  signing only when that file is absent. The wiring itself was verified with a real, disposable
  test keystore (built a real signed release APK, confirmed via `apksigner verify --print-certs`
  that the certificate was the test one, then deleted it) — the real production upload keystore
  was deliberately **not** generated in this session (one-way secret; see
  `docs/android/RELEASE_SIGNING_PROCEDURE.md` for the exact procedure Mylord runs).
- [x] **R8/shrink/obfuscation** — previously absent entirely (Part 11/12/13 update above), now
  enabled (`isMinifyEnabled`/`isShrinkResources = true`, `android/app/proguard-rules.pro`).
  Verified: a real shrunk release APK built cleanly with zero R8 warnings; `mapping.txt`/
  `usage.txt` inspected directly, showing real class removal and renaming. **Gap, honestly
  documented, not silently skipped**: no Android device/emulator exists in this environment
  (confirmed at Phase 8), so the shrunk APK's *runtime* behavior (does it actually launch, do
  login/browse/book still work) could not be verified — only build-time correctness was.
- [x] **App Check / Play Integrity** — was fully greenfield (no code, no doc, no dependency)
  before this phase; now has a real double-gate architecture (inert by default, mirroring the
  Google Maps scaffold's discipline from Phase 7) wired into `create-booking`/`proxipay-confirm`,
  logging-only server-side, never blocking. See `docs/security/APP_CHECK_ARCHITECTURE.md`.
- [x] **"No CI/CD pipeline exists at all"** (Part 11/12/13 update above) — no longer accurate as
  stated: `.github/workflows/ci.yml` now exists (analyze → test → build-release → manual-approval
  gate → deploy-stub). **Still a gap**: no CI service has actually run this pipeline yet (it
  activates the moment this repo is pushed to GitHub with Actions enabled — nothing else to do),
  and the deploy stage is a placeholder until a real Play Store deploy target/service account is
  wired.
- [x] **Versioning scheme** — re-confirmed unchanged and correct (`pubspec.yaml` `1.0.0+1`
  matching `app_version.dart`, per the Part 14 entry above) — no action needed, cross-referenced
  in `docs/PRODUCTION_READINESS.md` rather than re-documented.

## Update — 2026-07-04 (Backend Enterprise Completion, Phase 1 audit — CP1)

New gaps found during the Phase 1 ground-truth audit (`docs/backend-completion/
PHASE_1_FINAL_AUDIT.md`), explicitly out of that pass's Phase 2-11 scope and logged here instead:

- [ ] **Repository layer bypass** — 14 `presentation/` files call `SupabaseService` directly
  instead of going through their feature's repository (`staff_detail_screen.dart`,
  `home_owner_screen.dart`, `home_staff_screen.dart`, `client_profile_screen.dart`,
  `loyalty_scan_screen.dart`, `marketing_dashboard_screen.dart`, `payment_screen.dart`,
  `referral_claim_screen.dart`, `owner_reviews_screen.dart`, `salon_reviews_tab.dart`,
  `reset_password_screen.dart`, `accept_invitation_screen.dart`, `my_performance_screen.dart`,
  +1 more). Pre-existing, not a regression from this pass. Needs a dedicated refactor phase.
- [ ] **Repository/Datasource pattern not actually implemented** — only `lib/features/auth/data`
  has a `datasources/` split; all 23 other sampled/scanned features go straight from
  `RepositoryImpl` to `SupabaseService.client`. The documented pattern
  ("Repository + Datasource") is aspirational, not real, project-wide. Architectural debt, not
  in scope of the Backend Enterprise Completion pass.
- [ ] **Offline outbox: notification mutations undocumented** — `MutationOutboxService`/
  `OfflineSyncCoordinator` cover `reviewCreate`/`profileUpdate`/`dataDeletionRequest` only.
  Bookings are deliberately excluded with a documented reason (`docs/OFFLINE_STRATEGY.md §3`);
  notifications are excluded with **no equivalent justification comment**. Low-risk (no
  client-mutable notification-preference flow currently exists) but should get the same
  documentation treatment, or real coverage if such a flow is ever built.
- [ ] **CI pipeline existence vs. actual execution still unverified** — `.github/workflows/
  ci.yml` exists and a real GitHub remote is configured (`origin
  https://github.com/Mylord90/kynza-app.git`), but the `gh` CLI is unavailable in this dev
  environment, so no run history could be confirmed from here. Needs a check from a machine with
  `gh` authenticated, or the GitHub Actions tab directly — purely an external-verification gap,
  nothing to build.
- [ ] **iOS `Info.plist` still missing usage descriptions / URL scheme** — no
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, or `CFBundleURLTypes` present.
  Re-confirmed unchanged since the prior hardening pass. Still out of scope (iOS submission is
  an explicitly separate, later workstream), re-logged here so it isn't lost between passes.