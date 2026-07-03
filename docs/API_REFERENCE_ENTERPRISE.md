# KYNZA — External API Reference (Enterprise)

> Every integration below is checked against `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`,
> `ios/Runner/Info.plist`, and the actual Dart/TS code — verified 2026-07-03. Status is reported
> honestly: **configured** items are backed by real code; **pending** items have zero matching
> dependency or code and are marked as such, never implied to be "almost done."

## ⚠️ Critical finding surfaced during this audit

**`android/app/src/main/AndroidManifest.xml` (the release/main manifest) declares zero
`<uses-permission>` entries — including `INTERNET`.** `INTERNET` is present only in
`android/app/src/debug/AndroidManifest.xml` and `android/app/src/profile/AndroidManifest.xml`
(Flutter's default template comment there says it's "required for development... hot reload"
tooling, not for the app's own network calls). A **release build may have no network access at
all**, which would break every Supabase call, including login. Android's build-time manifest
merger can sometimes inject a permission from a dependency's own manifest, so this is not
proven to crash a real release build without inspecting the merged manifest output of an actual
`flutter build apk --release` — **which was not run as part of this documentation pass** (out of
scope, and this repo's release signing has its own known tech debt per `docs/PRODUCTION_CHECKLIST.md`).
This is flagged as a **high-priority, independently-verifiable candidate release-blocker**,
appended to Part 14, not silently fixed here (additive-docs-only scope).

Also verified absent from both `AndroidManifest.xml` and `Info.plist`: any `CAMERA`,
`READ_MEDIA_IMAGES`/`READ_EXTERNAL_STORAGE`, or `NSCameraUsageDescription`/
`NSPhotoLibraryUsageDescription` entries, despite `image_picker` and `mobile_scanner` being real,
used dependencies (ProxiPay QR scan, loyalty QR scan, avatar/salon photo upload). No
`permission_handler` package exists either. iOS in particular will hard-crash the process (not
just deny silently) if a camera/photo-library access attempt occurs with no matching
`NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` key in `Info.plist` — this is standard
iOS behavior, not speculative.

## Per-API Reference

| API | Purpose in KYNZA | Integration point | Permissions (exact keys) | Config source | Status | Fallback |
|---|---|---|---|---|---|---|
| **Google Maps** | Interactive salon discovery map | — | — | — | ⏳ **Pending — no `google_maps_flutter`/`geolocator`/`geocoding` package in `pubspec.yaml`** | `AdvancedSearchScreen`'s existing text/filter-based search is the only discovery mechanism today |
| **Google Places** | Address autocomplete for salon creation | — | — | — | ⏳ Pending — no package, no code | Manual free-text address entry (`SalonCreationWizardScreen`, confirmed real column `salons.address`) |
| **Directions / Distance Matrix / Routes API** | Distance-to-salon, route display | — | — | — | ⏳ Pending | n/a |
| **Geocoding / Reverse Geocoding** | Convert address ↔ lat/long | — | — | — | ⏳ Pending — `salons.latitude`/`longitude` columns exist (`docs/DATABASE_ARCHITECTURE.md` §3.2) but nothing populates them from an address today | Manual lat/long entry, if ever exposed, or left null |
| **Device Geolocation** | "Near me" discovery | — | — | — | ⏳ Pending — no `geolocator`/`ACCESS_FINE_LOCATION`/`NSLocationWhenInUseUsageDescription` anywhere | Text search only |
| **Firebase Cloud Messaging** | Push notifications | `lib/core/services/notification_service.dart`, `send-notification` Edge Function | Android: none explicit needed beyond manifest meta-data (`com.google.firebase.messaging.default_notification_icon/_color`, confirmed present); iOS: APNs entitlement (not verifiable from `Info.plist` alone — requires Xcode capability, not checked in this pass) | `firebase_messaging: ^15.0.0` (pubspec), `Firebase.initializeApp()` in `main.dart` | ✅ Configured | `notification_logs.channel='in_app'` row always written regardless of push delivery success (`docs/EDGE_FUNCTIONS_REFERENCE.md` §5, `send-notification`) |
| **Firebase Crashlytics** | Crash reporting | `lib/core/services/crash_reporting_service.dart`, `runZonedGuarded` in `main()` | none | `firebase_crashlytics: ^4.0.0` | ✅ Configured | n/a — failure of Crashlytics itself is silent by design (never blocks app boot) |
| **Firebase Analytics** | Event tracking | — | — | — | ⏳ **Pending — no `firebase_analytics` package in `pubspec.yaml`**, despite Part 6's `feature_ai`/dashboard docs implying analytics-adjacent capability; do not confuse with the real, unrelated in-house `analytics_views`/`mv_daily_revenue` SQL views (`docs/DATABASE_ARCHITECTURE.md`), which power the owner dashboard without Firebase Analytics | n/a |
| **Supabase Auth** | JWT issuance, session | `SupabaseService.auth`, `AuthNotifier` | — | `Env.supabaseUrl`/`supabaseAnonKey` via `--dart-define`, `flutter_secure_storage` for the JWT | ✅ Configured | Redirect chain forces `login` on any unresolved auth state (`docs/WORKFLOWS.md` §2.3) |
| **Supabase Database (Postgres + RLS)** | Primary store | throughout | — | Same env vars | ✅ Configured | n/a |
| **Supabase Storage** | Media, backups | `salon_media`, `create-backup` (`kynza-backups` bucket) | — | Same | ✅ Configured | n/a |
| **Supabase Realtime** | Live updates | `.stream()` builder, 10+ consumers (`docs/ARCHITECTURE_GLOBAL.md` §2.6) | — | Same | ✅ Configured | Last cached emission shown offline; SDK auto-reconnects |
| **Supabase Edge Functions** | Server-side business logic | 18 functions (`docs/EDGE_FUNCTIONS_REFERENCE.md`) | — | Vault secrets (`docs/SECURITY.md`) | ✅ Configured | Per-function error states, see that doc |
| **Google Sign-In** | OAuth login | `AuthSupabaseDatasource.signInWithGoogle()` | none needed client-side — routed through Supabase's hosted OAuth (`signInWithOAuth(OAuthProvider.google)`), no separate `google_sign_in` package required | Supabase Auth provider config (dashboard-side, not verifiable from this repo) | ✅ Configured, real button on login/register screens | n/a |
| **Facebook Login** | OAuth login | `AuthSupabaseDatasource.signInWithFacebook()` | none configured | — | ⏳ **Stub** — `throw UnimplementedError('... arrives in V2')`; button rendered with `onPressed: null` behind a "coming soon" tooltip (`docs/WORKFLOWS.md` §2.6) | Google or email/password |
| **Apple Sign-In** | OAuth login (iOS/Phase 8) | `AuthSupabaseDatasource.signInWithApple()` | none configured | — | ⏳ **Stub**, same pattern as Facebook | Google or email/password |
| **Leapa (Mobile Money)** | Payment processing | `create-payment`, `leapa-webhook`, `proxipay-confirm` Edge Functions | none client-side — Flutter never calls Leapa directly (R16, `docs/EDGE_FUNCTIONS_REFERENCE.md`) | Vault secrets `LEAPA_API_KEY`, `LEAPA_SECRET`, `LEAPA_WEBHOOK_SECRET` (`docs/SECURITY.md`) | ✅ Configured, live | "Payer sur place" (ProxiPay) if Mobile Money unavailable |
| **Bluetooth (ProxiPay BLE)** | Alternate ProxiPay transport | — | — | — | ⏳ **Pending — no Bluetooth package anywhere, no `TransportDetector` class** (confirmed absent, `docs/ARCHITECTURE_GLOBAL.md` §2.5/2.6 grounding) | QR is the only transport that exists |
| **NFC (ProxiPay)** | Alternate ProxiPay transport | — | — | — | ⏳ Pending, same as BLE | QR |
| **Camera** | QR scanning, photo capture | `mobile_scanner` (scan), `image_picker` (capture) | **Not declared anywhere** — see the critical finding above | `mobile_scanner: ^5.0.0`, `image_picker: ^1.1.2` | ⚠️ Package present, **permission declarations verified missing** | n/a — this is the gap itself |
| **Gallery / Photo picker** | Avatar, salon photo upload | `image_picker` | Same gap as Camera | `image_picker: ^1.1.2` | ⚠️ Same caveat | n/a |
| **Supabase Storage (upload path)** | Backing store for the above | `StorageService` | — | Same Supabase env vars | ✅ Configured | n/a |
| **Local Notifications** (`flutter_local_notifications`) | Scheduled/local push | — | — | — | ⏳ **Pending — package not in `pubspec.yaml`**; all push today is server-driven FCM only, consistent with `docs/ai/skills/kynza-offline-realtime.md` §9's rule that push notifications are never client-queued | n/a |
| **Dynamic Links / Deep Links** | Invitation/referral/salon/booking links | `DeepLinkHandler.parseRoute()`, Android intent-filters (`android:scheme="com.kynza.app"`) confirmed for exactly 4 hosts: `accept-invitation`, `accept-referral`, `salon`, `booking` | Custom URL scheme via native `<intent-filter>` (Android) — **no Firebase Dynamic Links / no `app_links`/`uni_links` package** — relies on Flutter's built-in platform-channel deep-link support, not a dedicated plugin | Native manifest only | ✅ Configured for Android (verified); **iOS `CFBundleURLSchemes` entry not found in `Info.plist`** — same custom scheme is very likely not wired on iOS, unconfirmed without a device test | Two of the 4 hosts (`accept-invitation`, `accept-referral`) queue the token via `SessionService` if the user isn't logged in yet; `salon`/`booking` have no such queue (`docs/WORKFLOWS.md` §2.4) |

## Contraintes & Edge Cases

- Every "⏳ Pending" row above reflects a genuine absence of code, not a partially-wired feature —
  do not build UI that assumes any of these exist without first adding the dependency and,
  where relevant, the platform permission declarations.
- The Camera/Gallery permission gap (⚠️ above) is more urgent than a typical "Pending" feature
  gap because the code **already calls** these plugins in production screens (ProxiPay scan,
  loyalty scan, profile/salon photo upload) — this isn't a future feature, it's an already-shipped
  feature with a missing platform declaration.

## Sécurité

Leapa and Supabase are the only APIs handling secrets; both keep them server-side only (Vault +
Edge Functions), never in the Flutter binary — consistent with `docs/SECURITY.md`. No API key for
any pending integration (Google Maps, etc.) exists in the codebase to leak, since none of those
integrations exist yet.

## Performance

Not applicable to pending integrations. For live ones: Realtime/Storage/Auth cost profile is
covered in `docs/PERFORMANCE_TARGETS.md` (Phase E).

## Documentation associée

- `docs/SECURITY.md` — Vault secrets inventory.
- `docs/EDGE_FUNCTIONS_REFERENCE.md` — Leapa/ProxiPay Edge Function detail.
- `docs/WORKFLOWS.md` §2.4/2.6 — deep link and OAuth provider ground truth.
- `docs/PRODUCTION_CHECKLIST.md` — the manifest-permissions finding appended there (Part 14).

## Critères d'acceptation

- [x] Every API marks its real current status — no pending item marked as done.
- [x] Every pending API lists its real fallback path, consistent with the existing QR-only
  ProxiPay pattern rather than an invented `TransportDetector`.
- [x] The permissions gap is reported with calibrated confidence (verified absent from source
  manifests; not verified against an actual built/merged manifest, and said so explicitly)
  rather than either overclaiming a guaranteed crash or hiding the risk.

## Livrables

- `docs/API_REFERENCE_ENTERPRISE.md` (this file)
