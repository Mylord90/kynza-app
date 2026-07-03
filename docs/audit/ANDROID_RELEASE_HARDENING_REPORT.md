# Phase 1 — Android Release Hardening Report

> Confirms and fixes the release-manifest permission gap flagged in the prior audit — with
> evidence, not assumption, per this pass's Rule 2. Every permission listed below was read from
> an actual `aapt`/`aapt2` dump of an actual `flutter build` output, not inferred from source.

## 1. Prior finding being tested

`docs/ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md` and `docs/PRODUCTION_CHECKLIST.md` both carry
a "🔴 candidate release-blocker": *"the release `AndroidManifest.xml` declares zero
`<uses-permission>` entries, including `INTERNET`... not confirmed against an actual
built/merged manifest."* Phase 0 re-confirmed the **source** manifest has zero permission
declarations. This phase builds the real release artifacts and inspects the **merged** manifest,
which is the only one that actually ships.

## 2. Build evidence

### 2.1 Release APK (split-per-abi) — first build, before any fix

```
flutter build apk --release --split-per-abi
```

```
√ Built build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk (28.4MB)
√ Built build\app\outputs\flutter-apk\app-arm64-v8a-release.apk (31.7MB)
√ Built build\app\outputs\flutter-apk\app-x86_64-release.apk (34.3MB)
```

Build succeeded cleanly (only non-blocking warnings: a Kotlin-Gradle-Plugin deprecation notice
from 6 transitive plugins, and Java 8 source/target obsolescence warnings — neither is a
permission or manifest issue, both carried forward as informational only, out of this phase's
scope).

### 2.2 Release AAB — first attempt crashed (environment issue, not a code/manifest issue)

```
flutter build appbundle --release
```

First attempt failed:

```
JVM crash log found: file:///D:/KYNZA-PROJET/android/hs_err_pid20316.log
FAILURE: Build failed with an exception.
Gradle build daemon disappeared unexpectedly (it may have been killed or may have crashed)
```

Root cause confirmed from the JVM crash log, not assumed: this machine has 8GB total RAM: at
crash time, `Memory: 4k page, system-wide physical 8033M (347M free)` and
`AvailPageFile size 24808M (AvailPageFile size 22M)` — i.e. virtual memory was essentially
exhausted. This happened because the AAB build was started concurrently with a second Gradle/
Kotlin daemon (the APK rebuild after the manifest fix, §3 below), and two simultaneous
Gradle+Kotlin-compiler JVMs on an 8GB machine ran the system out of memory. **This is an
environment/scheduling issue, not a manifest or code defect** — retrying the exact same build
sequentially (no concurrent Gradle daemon) succeeded on the first attempt with no other changes:

```
√ Built build\app\outputs\bundle\release\app-release.aab (75.5MB)
```

The stray `hs_err_pid20316.log` crash dump was deleted from `android/` after root-causing it —
it's a JVM artifact, not project state worth keeping.

## 3. Merged manifest permission audit — BEFORE the fix

```
aapt dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

```
package: com.kynza.app
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.WAKE_LOCK'
uses-permission: name='android.permission.POST_NOTIFICATIONS'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.USE_BIOMETRIC'
uses-permission: name='android.permission.USE_CREDENTIALS'
uses-permission: name='android.permission.CREDENTIAL_MANAGER_SET_ORIGIN'
uses-permission: name='com.google.android.c2dm.permission.RECEIVE'
permission: com.kynza.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='com.kynza.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
```

**Critical correction to the prior audit's finding**: the merged release manifest is **not**
empty. `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, and `CAMERA` are
all already present — auto-injected during Gradle's manifest merge from the dependency plugins'
own `AndroidManifest.xml` files (`supabase_flutter`/`gotrue`/`firebase_*` declare `INTERNET`
themselves; `connectivity_plus` declares `ACCESS_NETWORK_STATE`; `firebase_messaging` declares
`WAKE_LOCK`/`POST_NOTIFICATIONS`/the FCM receiver permissions; `mobile_scanner` declares
`CAMERA`). The prior finding was a reasonable caution given only the source manifest had been
read, but it does **not** hold once the actual merged/release manifest is inspected — the app
was never actually going to ship without network access.

`aapt dump badging` additionally confirms `targetSdkVersion:'36'`, `sdkVersion:'24'`, and that
the camera feature is correctly declared as **not required**
(`uses-feature-not-required: name='android.hardware.camera'`), so the Play Store won't exclude
camera-less devices even though `mobile_scanner` pulls in the `CAMERA` permission for ProxiPay/
loyalty QR scanning.

## 4. Cross-reference: permission vs. actual code usage

| Permission | Source plugin | Actually used in code? | Verdict |
|---|---|---|---|
| `INTERNET` | supabase_flutter / firebase_* (auto-merged) | Yes — every network call | **PRESENT, needed** |
| `ACCESS_NETWORK_STATE` | connectivity_plus | Yes — `lib/core/services/connectivity_service.dart` | **PRESENT, needed** |
| `WAKE_LOCK` | firebase_messaging (auto-merged) | Yes — FCM background delivery, `lib/core/services/notification_service.dart` | **PRESENT, needed** |
| `POST_NOTIFICATIONS` | firebase_messaging (auto-merged) | Yes — `NotificationService.initialize()` calls `requestPermission()` | **PRESENT, needed** |
| `CAMERA` | mobile_scanner | Yes — `proxipay_scan_screen.dart`, `loyalty_scan_screen.dart` (QR scanning) | **PRESENT, needed** |
| `com.google.android.c2dm.permission.RECEIVE` | firebase_messaging (auto-merged) | Yes — required system permission for any FCM/GCM receiver | **PRESENT, needed** |
| `com.kynza.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | firebase_messaging (auto-merged, Android 12+ requirement) | Yes — self-defined+used by the FCM broadcast receiver | **PRESENT, needed** |
| `USE_BIOMETRIC` | `passkeys` (fully **transitive** — pulled in by supabase_flutter/gotrue's WebAuthn support) | **No** — no passkey/biometric/credential-manager code anywhere in `lib/` (confirmed: `grep -ri "passkey"` across `lib/` returns zero matches; auth is email/password + OAuth only) | **UNNECESSARY — removed** |
| `USE_CREDENTIALS` | same (`passkeys`) | No | **UNNECESSARY — removed** |
| `CREDENTIAL_MANAGER_SET_ORIGIN` | same (`passkeys`) | No | **UNNECESSARY — removed** |

Checklist items from the prompt confirmed **correctly absent** (no plugin/code usage exists, so
nothing to add — adding them speculatively would violate the "never add just in case" fix
policy):

- `NFC`, `BLUETOOTH`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` — no NFC/
  Bluetooth package in `pubspec.yaml` and no matching code (`grep` for `nfc_manager`,
  `NfcManager`, `flutter_blue`, `FlutterBluePlus`, `BluetoothDevice` across `lib/` — zero
  matches). ProxiPay is confirmed QR-only in its current V1 state (matches memory:
  "ProxiPay V1 state" note on the vendor-patch commit) — BLE/NFC are a documented future
  extension, not live code, so their permissions are correctly not declared yet.
- `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED` — `image_picker` is
  used exactly once in the codebase (`media_upload_button.dart`), always with
  `ImageSource.gallery`, never `ImageSource.camera`. Modern `image_picker_android` versions
  invoke the system Photo Picker for gallery access, which requires **no** runtime permission at
  all on the SDK levels this app targets — consistent with these permissions being absent from
  the merged manifest.
- `VIBRATE` — haptics (`lib/core/utils/haptics.dart`) go through Flutter's
  `HapticFeedback` API, which on Android maps to `View.performHapticFeedback()`, not the raw
  `Vibrator` service — this does **not** require the `VIBRATE` permission, so its absence is
  correct, not a gap.
- `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE` — no boot-triggered work or foreground-service
  plugin exists in `pubspec.yaml` (reminders are server-side Postgres cron / Edge Functions, per
  memory, not a device-side scheduled task). Correctly absent.

## 5. Fix applied

`android/app/src/main/AndroidManifest.xml` — added an explicit `tools:node="remove"` override
for the 3 unnecessary permissions, with a comment naming the root cause (transitive `passkeys`
dependency, unused):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.USE_BIOMETRIC" tools:node="remove"/>
    <uses-permission android:name="android.permission.USE_CREDENTIALS" tools:node="remove"/>
    <uses-permission android:name="android.permission.CREDENTIAL_MANAGER_SET_ORIGIN" tools:node="remove"/>
    <application ...>
```

This is the standard Android manifest-merger mechanism for stripping a permission injected by a
transitive dependency's own manifest, without needing to fork/exclude the `passkeys` package
itself (which is several levels transitive and not directly controllable from `pubspec.yaml`).
No `INTERNET`/`CAMERA`/notification permission was touched — nothing needed was removed.

**No permission was added.** Every permission the app actually needs was already present via
plugin auto-merge before this phase started; this phase's only manifest change is a removal.

## 6. Merged manifest permission audit — AFTER the fix (proof)

Rebuilt from scratch after the manifest edit:

```
flutter build apk --release --split-per-abi   → succeeded
flutter build appbundle --release             → succeeded (75.5MB app-release.aab)
```

```
aapt dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

```
package: com.kynza.app
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.WAKE_LOCK'
uses-permission: name='android.permission.POST_NOTIFICATIONS'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='com.google.android.c2dm.permission.RECEIVE'
permission: com.kynza.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
uses-permission: name='com.kynza.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
```

**Diff (before → after):** `USE_BIOMETRIC`, `USE_CREDENTIALS`, and
`CREDENTIAL_MANAGER_SET_ORIGIN` are gone. Every other permission is unchanged. This is the exact
before/after diff required by this phase's fix policy.

### 6.1 AAB manifest — verification note

The AAB was rebuilt from the same source tree and the same Gradle `release` variant immediately
after the APK rebuild succeeded, so it goes through the identical manifest-merge task
(`process*ManifestForBundle`) with identical inputs. A second independent binary inspection of
the AAB's protobuf-format manifest was attempted via `bundletool build-apks`, but the only
`bundletool` artifacts available on this machine are library JARs pulled into the Gradle cache
by the Android Gradle Plugin (no `Main-Class` manifest entry, not runnable standalone) — no
`bundletool-all` CLI distribution is installed. This is a tooling gap of the same kind as Phase
0's missing Docker/psql, flagged here rather than silently skipped or asserted without evidence.
The AAB's permission set is **not independently re-verified by a second tool**, only verified by
construction (same source, same variant, same merge task as the already-proven APK). If a
byte-for-byte AAB check is required later, installing the standalone `bundletool` CLI (or Docker,
for `supabase db dump` in Phase 0/2) would close both gaps at once.

## 7. Acceptance criteria check

- [x] Release AAB/APK actually built (not simulated) — both artifacts exist on disk with real
      file sizes quoted above.
- [x] Merged manifest permission list captured via `aapt`, not inferred — before and after.
- [x] `INTERNET` and every actually-used permission confirmed present in the release build
      specifically — always was, disproving the prior "candidate release-blocker" as literally
      stated (the source manifest is empty, but the merged/shipped manifest never was).
- [x] Zero unused permissions remain declared — the 3 `passkeys`-sourced permissions were the
      only unused ones found, and they're now stripped.

## 8. Regression check

- `flutter analyze` → 0 issues (unchanged from Phase 0 baseline; expected, since the only change
  is an Android XML file, not Dart source).
- `flutter test` → 244/244 passing (unchanged from Phase 0 baseline).

## 9. Rollback

`git revert` the Phase 1 commit restores the original (unfixed) manifest; `pre-hardening-baseline`
remains the whole-pass fallback tag. No schema, no server-side, no Dart-code change was made in
this phase — the blast radius is a single Android manifest file.
