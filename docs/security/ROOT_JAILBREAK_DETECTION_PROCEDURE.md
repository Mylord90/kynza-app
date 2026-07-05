# Root / Jailbreak Detection — Activation Procedure

> Enterprise Final 100 CP2 deliverable — closes the root/jailbreak-detection half of P2-21
> (Master Inventory). The other half of P2-21 (certificate pinning) needs a real captured
> production TLS certificate — reclassified as an External Go-Live Dependency
> (`EXTERNAL_GO_LIVE_DEPENDENCIES.md`). This half does **not** depend on any external
> service/console configuration, but it does need a real rooted/jailbroken (or emulator-rooted)
> device to verify the actual detection logic — not available in this environment. Per this
> campaign's governing rule ("if something cannot be verified in this environment, say so
> explicitly and name what would be needed"), this is documented as a ready-to-execute procedure
> rather than shipped as unverified code.

## 1. Why this isn't code yet

Every native-dependency addition in this codebase (Google Maps, Firebase App Check) has followed
the same discipline: don't add the plugin until it can be verified doing something real. Root/
jailbreak detection specifically needs a rooted Android device/emulator or a jailbroken iOS
device/simulator to prove the positive case (detected) — a clean device only proves the negative
case (not detected), which is the trivial, uninteresting half. No such device/emulator exists in
this environment (confirmed: no Android device/emulator has existed in any pass of this program,
per the Master Plan's own Production Readiness section). Shipping unverified detection logic
would be exactly the "should be fine" class of claim this campaign's governing rule forbids.

## 2. Recommended package and integration point

`safe_device` (or `flutter_jailbreak_detection`, actively maintained alternatives — pick whichever
has the more recent release at activation time) — pure Dart-facing API, no server-side
configuration needed, unlike App Check/Play Integrity.

```yaml
# pubspec.yaml
dependencies:
  safe_device: ^<latest>
```

## 3. Activation procedure

1. Add the dependency, run `flutter pub get`.
2. Add a `RootJailbreakGate` class next to `AppCheckFeatureGate`
   (`lib/core/security/root_jailbreak_gate.dart`), same double-gate shape: an env-level opt-in
   (`bool.fromEnvironment('ROOT_DETECTION_ENABLED', defaultValue: false)`) AND a feature flag
   (`feature_root_detection`, same `evaluate_feature_flag` RPC every other flag uses) — mirrors
   `AppCheckFeatureGate`/`GoogleMapsFeatureGate` exactly, so this is a proven pattern, not a new one.
3. In `main.dart`, near the existing `Firebase.initializeApp()`/App Check activation block:
   ```dart
   if (RootJailbreakGate.isOptedIn) {
     final isCompromised = await SafeDevice.isJailBroken; // or the chosen package's equivalent
     if (isCompromised) {
       CrashReportingService.recordError(
         'compromised_device_detected', StackTrace.current,
       );
       // Per this program's own fallback discipline (see APP_CHECK_ARCHITECTURE.md §4):
       // log/monitor first, do not hard-block a legitimate user's device on the very first
       // rollout — false positives on legitimate custom ROMs are a known failure mode of every
       // root-detection library. Promote to an actual block only after a monitoring period
       // confirms the false-positive rate is acceptable.
     }
   }
   ```
4. **Verification step this environment cannot perform**: build a debug APK, install on a real
   rooted Android device (or an emulator image explicitly built with root, e.g. a Google APIs
   x86 image + Magisk), confirm `isCompromised` returns `true`; repeat on a clean device/emulator,
   confirm `false`. Both directions must be proven — do not ship on the strength of the clean-
   device case alone.
5. Only after a real device confirms both directions: flip `ROOT_DETECTION_ENABLED` on for a
   controlled rollout via the existing feature-flag admin screen, same rollout discipline as
   every other flag-gated feature in this codebase.

## 4. What this does NOT do (by design, same as App Check)

Does not block anything on its own — logging/monitoring only until a real device round-trip
proves the detection actually fires correctly in both directions. Does not touch any other
security control (certificate pinning, RLS, rate limiting) — a fully independent, additive
signal.
