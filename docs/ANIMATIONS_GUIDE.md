# KYNZA — Animations System

> Part 9. Grounded in real tokens (`lib/core/constants/app_durations.dart`,
> `app_curves.dart`), real widgets (`KynzaLoader`, `KynzaButton`, `KynzaBottomNav`,
> `RadarPulseWidget`), and the existing `docs/LOADER_GUIDE.md` (cross-linked, not duplicated).
> Verified 2026-07-03. Where the brief names an animation with no matching code, it's marked
> **not yet implemented** with a proposed spec using the existing token set — never presented as
> already shipped.

## 1. Objectifs

Codify motion so every new screen reuses the same duration/curve vocabulary instead of
hand-picking one-off values — and stay GPU-friendly on a Moto G06-class device (R13: no
`BackdropFilter`, prefer `AnimatedContainer`/`Opacity`/`Transform` over `CustomPainter` where
possible; `KynzaLoader` is the one deliberate, budgeted exception, see §2).

## 2. Token vocabulary (real, `lib/core/constants/`)

**Durations** (`AppDurations`): `micro` 80ms, `fast` 120ms, `standard` 200ms, `medium` 300ms,
`rich` 400ms, `spring` 500ms, `shimmer` 1500ms, `pageTransition` 320ms, `loaderOrbit` 1400ms
(explicitly commented "do not modify without explicit product validation").

**Curves** (`AppCurves`): `standard` = `easeInOutCubic`, `decelerate` = `easeOutCubic`,
`accelerate` = `easeInCubic`, `spring` = `elasticOut`, `sharp` = `easeInOutQuart`.

No screen should hand-pick a one-off `Curves.*`/`Duration(milliseconds: N)` outside this set —
enforced by convention (`app_curves.dart`'s own doc comment), not currently a lint rule.

## 3. Per-Animation Spec

| Animation | Trigger | Duration | Curve | Implementation | Status |
|---|---|---|---|---|---|
| Splash | App cold start | Owns its own minimum-display transition (`docs/WORKFLOWS.md` §2.3) — exact duration not centralized in `AppDurations` | — | `SplashScreen` | ✅ Real |
| `KynzaLoader` — orbit variant | Any loading state (default variant) | **1400ms/cycle** (`AppDurations.loaderOrbit`) | Per-particle `CurvedAnimation` (see `docs/LOADER_GUIDE.md`) | `CustomPainter` (`kynza_loader_painter.dart`) — the one deliberate `CustomPainter` exception to the "prefer Animated* widgets" rule, budgeted and named in `docs/LOADER_GUIDE.md` | ✅ Real — full spec in `docs/LOADER_GUIDE.md`, cross-linked not duplicated here |
| `KynzaLoader` — pulse variant | Small-space loading contexts | Same token, smaller render | Same | Same file | ✅ Real |
| Hero transitions (salon → detail) | Tap a salon card | Not verified as an explicit `Hero` widget in this pass — flagged for verification, not claimed | — | — | ⚠️ **Unverified** — do not assume a `Hero` animation exists without confirming a shared `heroTag` in `SalonDiscoveryScreen`/`SalonDetailScreen` |
| Page transitions (GoRouter) | Every navigation | **320ms** (`AppDurations.pageTransition`) | fade + slight rightward slide (`_fadeRoute()` helper, `docs/WORKFLOWS.md` §2.1) | `CustomTransitionPage` | ✅ Real |
| Card entrance | List/grid population | `AppDurations.rich` (400ms) fade+slide or `AppDurations.medium` (300ms) scale | `AppCurves.decelerate` (fade+slide) / `AppCurves.spring` (scale) | `KynzaAnimations.fadeSlideIn()` / `.scaleIn()` (`lib/core/animations/kynza_animations.dart`) — reusable, no per-screen `AnimationController` boilerplate | ✅ Real |
| Bottom nav selection (`KynzaBottomNav`) | Tab tap | **280ms** (`KynzaNavTheme.animationDuration`) | `Curves.easeInOutCubic` | Icon scale (26px active / 22px inactive), −8px vertical lift on active item, gold halo glow, all via `AnimationController` per nav item; **respects `MediaQuery.disableAnimations`** (reduced-motion accessibility, verified in code) | ✅ Real |
| FAB morph | — | — | — | — | ⏳ **Not yet implemented** — no FAB-morph code found; if built, should follow `AppDurations.medium`/`AppCurves.spring` per this token set |
| Search-as-you-type debounce | Typing in a search field | Debounce ~300ms (matches `AppDurations.medium`; the Realtime `.stream()` debounce documented in `docs/ai/skills/kynza-offline-realtime.md` §6 is a separate, DB-side 300ms debounce, not this one) | — | — | ⚠️ Debounce value not independently verified in `AdvancedSearchScreen` in this pass — treat the 300ms figure as the project's standard debounce convention, not a confirmed measurement |
| Button press feedback | Tap any `KynzaButton` | **80ms scale** (`AppDurations.micro`, scale to 0.97) + **120ms opacity** (`AppDurations.fast`, disabled state) | Implicit (`AnimatedScale`/`AnimatedOpacity` defaults) | `KynzaButton` — also fires `KynzaHaptics.light()` on tap | ✅ Real |
| Toggle switches | — | `AppDurations.fast`–`standard` (120–200ms) per general convention | `AppCurves.standard` | Standard Flutter `Switch`/`AnimatedContainer` pattern — no bespoke `KynzaToggle` widget found | ⏳ Convention, not a dedicated verified widget |
| Success/error micro-animations | Toast/dialog appearance | `AppDurations.standard`–`medium` (200–300ms) | `AppCurves.decelerate` | `KynzaToast` (4 levels: success/error/warning/info, per `docs/ai/skills/kynza-uiux-design-system.md` §"KynzaToast" — real widget file `kynza_toast.dart` confirmed to exist) | ✅ Real widget; exact internal timing not independently re-verified against the skill doc's example in this pass |
| Payment confirmation (ProxiPay success pulse) | Successful payment | ~2s per the payments skill doc (`docs/ai/skills/kynza-payments-leapa.md` §7's "Succès paiement" row) | — | — | ⚠️ Skill-doc claim, not independently re-verified against `PaymentSuccessView` code in this pass |
| USSD waiting (Mobile Money) | Payment initiated | **3-minute real timeout, ~60s perceived** via `RadarPulseWidget` | — | `RadarPulseWidget` — **real, verified**: 3 concentric gold circles + center spinner, 2-second `AnimationController.repeat()` cycle, explicit in-code comment "NEVER Lottie here (R13 — Moto G06 RAM constraint)" | ✅ Real |
| ProxiPay QR scan feedback | Camera detects QR | Not independently verified in this pass | — | `mobile_scanner` overlay, `proxipay_qr_screen.dart`/`proxipay_scan_screen.dart` | ⚠️ Unverified |
| BLE/NFC "connecting" states | — | — | — | — | ⏳ **N/A — BLE/NFC are not implemented at all** (`docs/API_REFERENCE_ENTERPRISE.md`) |
| Loyalty stamp animation | Stamp added to card | Not independently verified | — | `loyalty_stamp_functions.sql` triggers the data change; client-side animation on receipt not confirmed in this pass | ⚠️ Unverified |
| Chart entrance (fl_chart) | Dashboard screen load | `AppDurations.rich` (400ms) fade-in convention | `AppCurves.decelerate` | fl_chart's own built-in animation duration is configurable per chart widget — not independently audited per-chart in this pass | ⚠️ Convention proposed, not verified per chart instance |
| Dashboard skeletons | Any loading dashboard tile | `AppDurations.shimmer` (1500ms shimmer period, matches `docs/ai/skills/kynza-uiux-design-system.md`'s 1200ms `Shimmer.fromColors` example closely enough to be the same family — the two values weren't reconciled to an exact single source in this pass) | — | `KynzaSkeleton` / `KynzaCardSkeletons` (real widget files confirmed) | ✅ Real, exact ms not independently re-verified |
| Marketing banner carousel | Owner marketing screen | Not independently verified | — | — | ⚠️ Unverified |
| Onboarding swipe | First-run onboarding | Not independently verified — no dedicated onboarding swipe screen confirmed found in this pass | — | — | ⚠️ Unverified — do not assume a bespoke onboarding carousel exists without confirming |
| General micro-interactions (button press, toggle) | Various | See Button press / Toggle rows above | — | — | — |

## 4. Performance Budget (Moto G06 class, R13)

- **No `BackdropFilter`/blur anywhere** — confirmed zero real usage repo-wide (only the rule
  documented as a comment in `app_shadows.dart`, per `docs/PRODUCTION_CHECKLIST.md`).
- **No Lottie** in any currently-shipped animation — `KynzaLoader` and `RadarPulseWidget` are both
  deliberately hand-built `CustomPainter`/`AnimationController` implementations specifically to
  avoid Lottie's RAM cost on low-end devices (explicit in-code comments on both). If Lottie is
  ever introduced (the brief lists `assets/lottie/`, Part 8), the existing skill-doc rule applies:
  gate it behind a RAM check (`device_info_plus` — **not currently a dependency**, would need
  adding) and always ship a static/native-Flutter fallback.
- `KynzaLoader`'s `CustomPainter` is the one budgeted exception to "avoid CustomPainter for
  continuous animation" — it's a small, bounded, single-instance widget, not a scroll-coupled or
  per-list-item painter, which is the actual performance risk `docs/LOADER_GUIDE.md`/the design
  skill doc are guarding against.
- `RepaintBoundary` candidates: `KynzaLoader` (continuous animation, isolate its repaints from
  the rest of the tree) and `KynzaBottomNav` (per-item `AnimationController`s) are the two
  highest-value candidates given they run continuously/on every navigation — not confirmed
  whether `RepaintBoundary` is already applied to either in this pass.
- 60fps target: no dropped-frame budget was independently measured in this pass (would require
  the Flutter Performance overlay/DevTools on a real Moto G06 device) — see Part 13
  (`docs/PERFORMANCE_TARGETS.md`) for the numeric targets and measurement method.

## 5. Contraintes & Edge Cases

Several rows above are marked ⚠️ **Unverified** rather than confirmed — this is deliberate. A
prior finding in this same documentation pass (Phase A/B) established that `docs/ai/skills/*.md`
files describe target/aspirational specs that have drifted from real code in more than one case
(offline architecture, payments refund flow). Rather than repeat that mistake here by copying
skill-doc animation claims as fact, every claim sourced only from a skill doc (not independently
re-confirmed against the actual widget's source in this pass) is marked accordingly.

## 6. Sécurité

N/A — no security surface in pure animation code.

## 7. Performance

Covered in §4; numeric fps/frame-budget targets are Part 13's responsibility, cross-linked there.

## 8. Stratégie de tests

No animation-specific widget tests exist in the 244-test suite currently. Recommended: a golden
test or `AnimationController` state assertion for `KynzaLoader`'s orbit cycle and
`RadarPulseWidget`'s 2s repeat, since both have explicit "do not modify without validation"
comments in source — a regression test would catch an accidental timing change.

## 9. Documentation associée

- `docs/LOADER_GUIDE.md` — full `KynzaLoader` component reference (not duplicated here).
- `docs/ai/skills/kynza-uiux-design-system.md` §6 — original animation table (some claims
  reconciled/flagged above, not all independently re-verified).
- `docs/ai/skills/kynza-payments-leapa.md` §7 — ProxiPay/USSD timing claims.
- `docs/DESIGN_SYSTEM.md` (Part 10) — motion tokens as part of the broader token system.
- `docs/PERFORMANCE_TARGETS.md` (Phase E) — numeric fps/frame budgets.

## 10. Critères d'acceptation

- [x] Every animation with real code has a concrete duration and curve sourced from the actual
  token files, not invented.
- [x] Animations named in the brief with no matching code are marked **not yet implemented**
  rather than described as shipped.
- [x] No animation spec relies on `BackdropFilter` — confirmed zero usage repo-wide.
- [x] Claims sourced only from a skill doc (not re-verified against real widget source in this
  pass) are explicitly flagged, given the established pattern of skill-doc/code drift found
  earlier in this documentation effort.

## 11. Livrables

- `docs/ANIMATIONS_GUIDE.md` (this file)
