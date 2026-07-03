# Phase 1 — Backend Enterprise Final Audit

> Checkpoint CP1 of the Backend Enterprise Completion pass. Ground-truth audit before any change
> — every claim below is a real command/grep output re-run today (2026-07-04), not a restated
> assumption. Baseline going in: `flutter analyze` 0 issues, `flutter test` 326/326, git HEAD
> `7c7d7fc` (`post-hardening-v1`).

## 1. Objectifs

Close every remaining unknown from the prior Enterprise Hardening pass's final report
(`docs/ENTERPRISE_HARDENING_REPORT.md` §6/§7), and establish ground truth on Flutter
architecture, Supabase schema/RLS, Edge Functions, and offline/sync coverage before CP2-CP7 make
any change.

## 2. Architecture — Flutter

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 1 | Feature-first layering | ✅ | 27 feature directories under `lib/features/`, each generally `data/domain/application/presentation`. |
| 2 | Layering violation: presentation calling `SupabaseService` directly | 🟡 gap | 14 files bypass the repository layer (`staff_detail_screen.dart`, `home_owner_screen.dart`, `home_staff_screen.dart`, `client_profile_screen.dart`, `loyalty_scan_screen.dart`, `marketing_dashboard_screen.dart`, `payment_screen.dart`, `referral_claim_screen.dart`, `owner_reviews_screen.dart`, `salon_reviews_tab.dart`, `reset_password_screen.dart`, `accept_invitation_screen.dart`, `my_performance_screen.dart`, +1). Goes through the `SupabaseService` facade (no raw `SupabaseClient` in presentation), but still skips the repository. **Newly discovered — assigned to `docs/PRODUCTION_CHECKLIST.md`** (dedicated refactor, out of this prompt's Phase 2-11 scope; not a regression, pre-existing). |
| 3 | Riverpod provider graph | ✅ | 64 files use classic `Provider(`/`NotifierProvider(`/`StreamProvider(` (no `@riverpod` codegen anywhere). Spot-checked booking/salon/staff provider files: no cross-feature circular imports found. |
| 4 | GoRouter route tree completeness | ✅ | Router at `lib/core/router/app_router.dart` (1340 lines, 76 `_fadeRoute(` registrations). Of 89 screens, 19 are not directly routed but all verified reachable via `Navigator.push`/wizard-step composition from a routed parent (booking flow, salon-creation wizard, staff forms, automation logs, etc.). **No orphan screens.** |
| 5 | Repository/Datasource pattern | 🟡 gap | Documented pattern is "Repository + Datasource (remote/local)" but only `auth/data` actually has a `datasources/` split. All 23 other sampled/scanned features go straight from `RepositoryImpl` to `SupabaseService.client`. **Newly discovered — assigned to `docs/PRODUCTION_CHECKLIST.md`** (architectural debt, not in scope of Phases 2-11). |
| 6 | Freezed/JSON serializable coverage | ✅ | `@freezed` in 57 files, `@JsonSerializable` in 52, out of 164 model-shaped files. No `@HiveType`/`HiveObject` usage anywhere — Hive is key-value only (session/permission/outbox caches), so there is no "persisted-but-unserialized" risk. |
| 7 | Dependency injection wiring | ✅ | Single centralized bootstrap in `lib/main.dart` (`_bootstrap()` → Hive/Firebase/Supabase init → one `runApp(ProviderScope(...))`). No duplicate wiring found. |

## 3. Feature Flags & RBAC — current state (feeds CP2/CP3)

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 8 | Feature Flags current scope | 🟡 → **CP2** | Implementation at `lib/features/evolution/feature_flags/*`. Schema: `feature_flags` (global) + `salon_feature_overrides` (per-salon), evaluated via RPC `evaluate_feature_flag`. **No per-role/per-user scope column exists.** `evaluateFlag()` is called from nowhere except its own repository — no screen actually gates on a flag yet. A 27-flag registry is documented in a draft migration (`20260703140000_feature_flags_registry.sql`) but unapplied. **Directly assigned to Phase 3/CP2** — matches that phase's explicit objective to widen scope granularity and wire real consumption. |
| 9 | RBAC / `SYSTEM_ADMIN` scope | 🔴 → **CP3** | Base roles: `enum UserRole { owner, manager, staff, client }` (`lib/core/enums/user_role.dart`) — **no internal-admin role exists**. Confirmed via `grep -rn "SYSTEM_ADMIN\|SystemAdmin\|system_admin"` across `lib`, `docs`, `supabase` — zero hits outside this pass's own planning doc. Server-side, access control mostly routes through a granular `check_permission` RPC + permission-groups (`lib/features/permissions/`), only 1 migration file has hardcoded `role = 'owner'` string checks. **Must be created from scratch in Phase 2/CP3** before any admin-only dashboard can be RBAC-gated, exactly as that phase anticipates. |

## 4. Supabase schema / RLS / Edge Functions

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 10 | Migration count / applied state | ✅ | `ls supabase/migrations/*.sql` → **64** local files (unchanged from hardening report). `supabase migration list --linked` → **59 applied / 5 unapplied**, matching exactly. Unapplied drafts: `20260703120000_indexes_optimization.sql`, `20260703130000_catalog_schema.sql`, `20260703140000_feature_flags_registry.sql`, `20260703150000_legal_center.sql`, `20260703160000_health_dashboard_views.sql`. **Rule 8 held** — re-confirmed today, not just restated. |
| 11 | RLS coverage | ✅ | 132 `CREATE POLICY` across 35 files; 55 distinct tables (of the 59 applied) have RLS enabled — exact 1:1 match with the applied table count. Spot-checked `bookings` policy (owner/manager via `has_role()`, practitioner via `staff_profiles` join, client via `client_id = auth.uid()`) — correctly tenant-scoped. 3 `USING (true)` policies found (`feature_flags`, `maintenance_windows`, `app_versions`) — all `SELECT`-only on non-sensitive read-only config tables, not a red flag. No overly-permissive policy found on any sensitive table. |
| 12 | Edge Functions | ✅ | 18 real functions under `supabase/functions/` (`_shared` excluded). `docs/EDGE_FUNCTIONS_REFERENCE.md` lists exactly the same 18 — **zero drift** either direction. |
| 13 | Indexes/views/triggers/RPC (baseline count for later phases) | ✅ informational | `CREATE INDEX`: 100 · `CREATE VIEW`: 12 · `CREATE MATERIALIZED VIEW`: 2 · `CREATE TRIGGER`: 48 · `CREATE OR REPLACE FUNCTION`: 45. Recorded as the pre-CP2..CP7 baseline so later phases' additions are auditable deltas. |
| 14 | Table count vs. `docs/DATABASE_ARCHITECTURE.md` | ✅ | Doc claims 55 live tables. Grep confirms exactly 55 `CREATE TABLE` among the 59 applied migrations (1:1 with the RLS-table count above) — **no drift**. Will become 64 once the 5 drafts are applied (9 new tables net, `categories` in the catalog draft is `IF NOT EXISTS` and already exists remotely). |
| 15 | Offline/sync outbox coverage | 🟡 gap | `MutationOutboxService` + `OfflineSyncCoordinator` cover exactly 3 entities: `reviewCreate`, `profileUpdate`, `dataDeletionRequest`. Bookings are **deliberately** excluded (documented in `docs/OFFLINE_STRATEGY.md §3` — server-authoritative slot allocation). Notifications are **not covered and undocumented** (no equivalent justification comment). **Newly discovered — assigned to `docs/PRODUCTION_CHECKLIST.md`** as a documentation follow-up (add the same style of justification comment, or add coverage if a client-mutable notification-preference flow is ever built — neither is in scope of Phases 2-11 as currently written). |

## 5. Prior hardening pass's open items — re-verified today

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 16 | CI actually running | 🔴 still open | `.github/workflows/ci.yml` exists, real GitHub remote (`origin https://github.com/Mylord90/kynza-app.git`) configured. `gh` CLI is not installed in this environment, so no run history could be queried from here. **Unresolved, assigned to `docs/PRODUCTION_CHECKLIST.md`** — needs verification from a machine with `gh` authenticated or the GitHub Actions tab directly; nothing to build, purely an external-verification gap. |
| 17 | App Check / Play Integrity | ✅ resolved | Confirmed `5ef8ff6` is the same hardening-pass work the final report already describes (not separate, later work) — double-gated, logging-only, `feature_app_check` flag not applied remotely. No duplication, no drift. |
| 18 | Certificate pinning | 🔴 still open (by design) | `CertificatePinningService` wired in `lib/main.dart:79` but `featureFlagEnabled = false`, `pinnedCertificateDerBytes = []` — always returns an unpinned client. No verified production cert hash exists yet. Unchanged from hardening report — stays out of scope (needs a real cert from a deployed backend domain, a business/ops action). |
| 19 | Google Maps scaffold | 🔴 still open (by design) | `Env.googleMapsApiKey` empty by default, `pubspec.yaml` has no `google_maps_flutter`. Unchanged — stays out of scope per the roadmap's own "Google Maps go-live" remaining workstream. |
| 20 | iOS `Info.plist` gaps | 🔴 still open | No `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, or `CFBundleURLTypes` in `ios/Runner/Info.plist` (75 lines, boilerplate only). **Assigned to `docs/PRODUCTION_CHECKLIST.md`** — iOS submission itself remains explicitly out of this prompt's scope (per the roadmap's remaining-workstreams list), so not fixed in this pass, but re-confirmed and re-logged so it isn't lost. |
| 21 | 8 unbounded repository stream/fetch methods | 🟡 still open, tracked | `docs/audit/ACCESSIBILITY_PERFORMANCE_PASS.md §5` still lists all 8 by name, explicitly deferred to "a different phase's worth of careful, screen-by-screen verification." Re-confirmed unchanged — remains tracked there, not duplicated into a second doc. |
| 22 | Runtime launch verification of release APK | 🔴 still open (environmental) | `flutter devices` → Windows desktop, Chrome, Edge only. No Android device/emulator available in this environment. Unchanged — flagged as a required manual step before shipping. |
| 23 | Real production upload keystore | ✅ correctly absent | `android/key.properties` does not exist — deliberately Mylord-only, never generated by any automated session. This is the expected state, not a gap. |

## 6. Newly discovered gaps and their assignment

| Gap | Assigned to |
|---|---|
| 14 files bypass repository layer via direct `SupabaseService` calls in `presentation/` | `docs/PRODUCTION_CHECKLIST.md` (out of Phase 2-11 scope — dedicated refactor) |
| Repository/Datasource pattern inconsistent (only `auth` has a datasource split) | `docs/PRODUCTION_CHECKLIST.md` (out of Phase 2-11 scope — architectural debt) |
| Feature Flags: no per-role/per-user scope, `evaluateFlag()` unused by any screen, 27-flag registry migration unapplied | **Phase 3 / CP2** (already in scope, confirmed as that phase's real starting point) |
| No `SYSTEM_ADMIN` RBAC scope exists | **Phase 2 / CP3** (already in scope — that phase's spec already anticipates creating it) |
| Notification mutations not covered by offline outbox, and undocumented (unlike the bookings exclusion) | `docs/PRODUCTION_CHECKLIST.md` (documentation follow-up) |
| CI pipeline exists but no run has ever been verified from this environment | `docs/PRODUCTION_CHECKLIST.md` (external verification, `gh` CLI unavailable here) |

No item from the prior audit's open-items list is left with an unresolved ⬜ — every one of #16-23 above has an explicit ✅/🟡/🔴 verdict with evidence and, where still open, an explicit owner (either a specific later phase in this pass, or `docs/PRODUCTION_CHECKLIST.md` for out-of-scope items).

## 7. Gate evidence for CP1

- `flutter analyze` → 0 issues (re-run this checkpoint; no code was changed, audit-only).
- `flutter test` → 326/326 passing (re-run this checkpoint; no code was changed, audit-only).
- No live/remote Supabase migration applied — this phase performed read-only queries
  (`supabase migration list --linked`) only, no `db push`.
- No Track B scope touched (this checkpoint is Phase 1 only).

## 8. Exit Criteria

- [x] Every item from the previous audit's open-items list (§5, items 16-23) is now closed with
      an explicit verdict and evidence.
- [x] Every newly discovered gap (§6) is logged and assigned to the correct Phase 2-11 (Feature
      Flags gaps → Phase 3/CP2, RBAC gap → Phase 2/CP3) or to `docs/PRODUCTION_CHECKLIST.md` if
      out of this prompt's scope (layering violations, datasource-pattern inconsistency,
      notification-outbox documentation, CI-run external verification, iOS Info.plist).
