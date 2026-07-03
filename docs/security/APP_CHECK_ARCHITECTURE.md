# App Check / Play Integrity — Architecture & Activation Procedure

> Phase 10 (Production Readiness) deliverable — abuse-prevention architecture for the two
> sensitive Edge Functions named in the phase brief: `create-booking`, `proxipay-confirm`.
> Fully greenfield before this phase (confirmed by research: zero references to
> Integrity/AppCheck anywhere in `lib/` or `supabase/functions/`, no `firebase_app_check`
> dependency). Scaffolded following the exact same discipline as the Google Maps scaffold
> (Phase 7): a real double-gate exists and is tested, but the heavy native SDK is **not** added
> as a dependency while the feature is unused — inert by default, real activation is a documented,
> deliberate future step, not something silently half-wired.

## 1. What exists today

- **Client-side double gate** (`lib/core/security/app_check_feature_gate.dart`,
  `lib/core/constants/env.dart`): `AppCheckFeatureGate.isOptedIn` (from
  `Env.appCheckEnabled`, a `bool.fromEnvironment('APP_CHECK_ENABLED', defaultValue: false)`) AND
  `feature_app_check` (evaluated via the existing `evaluate_feature_flag` RPC — same mechanism
  every other flag in this app uses). Both must hold. Proven inert by test
  (`test/unit/app_check_feature_gate_test.dart`) — the feature-flag half is never even evaluated
  while the env-level opt-in is false, mirroring `GoogleMapsFeatureGate`'s proof shape exactly.
- **`AppCheckService.headers()`** (`lib/core/security/app_check_service.dart`) — always returns
  `{}` today. Wired into the two named call sites:
  `lib/features/booking/data/repositories/booking_repository_impl.dart`'s `createBooking()` and
  `lib/features/proxipay/data/repositories/proxipay_repository_impl.dart`'s `confirmSession()`,
  via the `headers:` parameter already supported by `SupabaseClient.functions.invoke()`.
- **Server-side logging** (`supabase/functions/_shared/app_check.ts`, called from
  `create-booking/index.ts` and `proxipay-confirm/index.ts`) — reads an `X-App-Check-Token`
  header if present and logs one of two states (absent / present-but-unverified). **Never
  blocks a request under any condition** — this is the literal fallback behavior the phase brief
  requires: "never hard-lock a legitimate user out, degrade with logging."
- **Feature flag registry entry** — `feature_app_check` added to the still-unapplied draft
  migration `supabase/migrations/20260703140000_feature_flags_registry.sql` (`is_enabled: false,
  rollout: 0`), matching `feature_google_maps`'s precedent in the same file. Not applied to the
  remote project in this pass (Rule 8).

## 2. Why no `firebase_app_check` dependency yet

Adding the real SDK now would mean carrying a native dependency (and a fresh
`flutter build`+`aapt` permission-diff cycle, per this pass's own established discipline for any
native-dependency change) for a feature that cannot actually be exercised: Play Integrity
requires linking this app's Play Console listing to its Firebase project and enabling the Play
Integrity API in Google Cloud Console — external, one-time console configuration nobody has done
yet for this app. Wiring the SDK without that configuration would either crash on `activate()` or
silently no-op, neither of which is better than the current, honestly-inert scaffold. This
mirrors the Google Maps precedent exactly (no `google_maps_flutter` dependency either, for the
same reason: no real API key exists to make it do anything).

## 3. Real activation procedure (future work, once Play Console/Firebase Console setup is done)

1. In Google Cloud Console (the project backing this app's Firebase project): enable the **Play
   Integrity API**.
2. In the Firebase Console → App Check: register the Android app, select **Play Integrity** as
   the provider.
3. Add the dependency: `firebase_app_check: ^<latest>` to `pubspec.yaml`.
4. In `lib/main.dart` (near the existing `Firebase.initializeApp()` call), add:
   ```dart
   if (AppCheckFeatureGate.isOptedIn) {
     await FirebaseAppCheck.instance.activate(
       androidProvider: AndroidProvider.playIntegrity,
     );
   }
   ```
5. Replace `AppCheckService.headers()`'s `return const {};` body with:
   ```dart
   final token = await FirebaseAppCheck.instance.getToken();
   return token == null ? const {} : {'X-App-Check-Token': token};
   ```
6. Build with `--dart-define=APP_CHECK_ENABLED=true` and flip the `feature_app_check` flag on
   (via the existing feature-flag admin screen) for a controlled rollout — the double gate means
   neither step alone activates anything.
7. Only once real tokens are flowing and have been observed in the `create-booking`/
   `proxipay-confirm` logs for a while: implement real verification in
   `supabase/functions/_shared/app_check.ts` (call Firebase's token verification, treat a failed
   verification as a **logged event, still never a blocked request** — abuse response should be
   rate-limiting/monitoring-driven, not a hard 403, per the phase brief's own fallback
   requirement) and only then consider promoting it to an actual enforcement gate, as a separate,
   deliberate, future decision.

## 4. What this does NOT do (by design)

- Does not block, rate-limit-harder, or otherwise treat requests differently based on App Check
  status today — purely observability, wired but inert.
- Does not touch any other Edge Function — only the 2 named in the phase brief. Extending this to
  more functions (e.g. `create-payment`, `claim-referral`) is straightforward (same
  `logAppCheckStatus` helper) but out of scope until this pattern is actually activated and
  proven useful on the first 2.
