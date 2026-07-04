# CP9 — Play Store & App Store Go/No-Go `[NEW DEPTH]`

## Play Store — 🔴 No-Go

| Check | Status |
|---|---|
| Android manifest/permissions | No regression since Phase 1 hardening (not independently re-audited line-by-line this pass — no changes to `AndroidManifest.xml` occurred in CP1-CP8) |
| R8/obfuscation | ✅ Confirmed intact (CP6) |
| **Signing** | 🔴 **Blocker** — no real upload keystore (`android/key.properties` absent); release build falls back to debug signing. Cannot produce a Play-Store-submittable artifact today. |
| Play Integrity / App Check | Present in code (`app_check_service.dart` + Edge Function-side checks on `create-booking`/`proxipay-confirm` only, per the existing cert table), not end-to-end re-verified live (requires a real device) |
| Data Safety Form | Not started — no evidence of a completed Play Console Data Safety declaration anywhere in the repo/docs |
| Backend readiness | 🔴 **Blocker** — Gate 0 P0 unresolved in production, 14 feature migrations undeployed (CP5/CP8) |
| CI/CD | Never executed (CP6) — not itself a store blocker, but no automated release pipeline exists to produce a signed artifact reproducibly |

**Verdict: No-Go.** Blocking items: (1) generate and secure a real upload keystore, (2) resolve
Gate 0's P0 and get the security-critical migrations applied, (3) complete the Play Console Data
Safety form, (4) decide and execute a release-build process (manual or CI-driven).

## App Store — 🔴 No-Go, iOS not started

Checked directly rather than re-citing the prior pass's own finding:

- `ios/Runner/`: only the default Flutter-generated scaffold (`AppDelegate.swift`,
  `SceneDelegate.swift`, `Info.plist`, boilerplate assets) — no KYNZA-specific iOS work exists.
- `ios/Runner.xcodeproj/project.pbxproj`: `CODE_SIGN_STYLE = Automatic`, no `DEVELOPMENT_TEAM` set
  — no real Apple Developer account is wired to this project.
- No `GoogleService-Info.plist` anywhere under `ios/` — Firebase (push notifications, Crashlytics)
  is not configured for iOS at all, even though it is for Android.
- No App Store Connect app record, no TestFlight configuration, no iOS-specific entitlements file
  found.

**Verdict: No-Go — this is not a punch list, it's a full second-platform launch effort.** Blocking
items: Apple Developer Program enrollment, Firebase iOS app registration + `GoogleService-Info.plist`,
real code signing (team + provisioning profiles), an App Store Connect record, a full iOS build
and manual test pass (nothing here has ever been built for iOS), and eventually App Store Review
submission. Not manufacturing a partial pass — this pass's own instructions require exactly this
honesty when the real answer is "not started."

## Exit criteria

- [x] Two explicit Go/No-Go verdicts, each with the exact blocking items listed.
- [x] iOS verdict is a real "not started," not a fabricated partial score.
