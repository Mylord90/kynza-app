# KYNZA — Performance Targets

> Part 13. Target device: Moto G06 class (entry-level Android, the realistic Burundi-market
> device profile per constraint #13 in the project brief). **No profiling was run against a real
> device in this documentation pass** — every target below is a numeric goal to measure against,
> not a confirmed current measurement, and is labeled accordingly. Where a real code-level token
> already constrains part of the answer (e.g. page transition duration), that's cited as the
> actual current value.

## 1. Objectifs

Concrete, numeric performance budgets — no "should feel fast," every target is a measurable
number with a stated measurement method, per the brief's own requirement.

## 2. Metrics, Targets, and Measurement Method

| Metric | Target | Current baseline | How to measure |
|---|---|---|---|
| Cold start (to first interactive frame) | **< 2.5s** | **Not measured in this pass** | Flutter DevTools "Time to First Frame" / Firebase Performance Monitoring (not currently integrated — no `firebase_performance` package in `pubspec.yaml`, confirmed absent) |
| Hot start | **< 800ms** | Not measured | Same tooling |
| Navigation transition (perceived) | **< 300ms** | **320ms actual** (`AppDurations.pageTransition`, real token, `docs/ANIMATIONS_GUIDE.md`) — 20ms over the target; close enough to not be a practical concern, flagged for awareness rather than urgency | Stopwatch/DevTools timeline against the real `_fadeRoute()` transition |
| Search debounce / response (offline-cache-first) | **< 400ms** perceived | Not measured; **the "offline-cache-first" half of this target is currently unachievable** — no offline cache exists for search results (`docs/OFFLINE_STRATEGY.md`) | DevTools timeline on `AdvancedSearchScreen` |
| Payment confirmation round-trip (ProxiPay QR confirm, 3G) | **< 3s** | Not measured; `proxipay-confirm`'s Edge Function has no explicit timeout configured (`docs/EDGE_FUNCTIONS_REFERENCE.md` §7), so nothing currently *bounds* this to 3s even if it were measured once and happened to be fast | Manual 3G-throttled test (Chrome DevTools network throttling equivalent, or a real low-bandwidth device test) |
| Animation frame budget | **60fps, no dropped frames >16.6ms** on primary flows | Not measured | Flutter Performance overlay (`WidgetsApp.showPerformanceOverlay`) on a real Moto G06 or equivalent |
| Memory footprint (steady state) | **< 180MB** on a 2GB RAM device | Not measured | Android Studio Profiler / `flutter run --profile` memory tab |
| CPU/GPU budget — chart-heavy dashboard | Not separately numeric-targeted beyond the 60fps rule above | Not measured | Same Performance overlay, specifically on `AdvancedDashboardScreen`'s `fl_chart` widgets |
| Battery impact — BLE/NFC scanning | **N/A — not applicable today** | BLE/NFC are confirmed **not implemented anywhere** in this codebase (`docs/API_REFERENCE_ENTERPRISE.md`) — this target has nothing to measure against; if BLE/NFC scanning is ever built, the rule (must stop scanning outside an active ProxiPay flow) should be enforced at that time, not before |
| Offline mode load time (cached data, no network) | **< 500ms** | **Currently unachievable for most screens** — per `docs/OFFLINE_STRATEGY.md`, only `kynza_prefs`/`permission_cache` are disk-cached; a cold start offline on any `.stream()`-backed screen (bookings, services, loyalty, etc.) has no cached data to render at all, so this target cannot be met until Part 11's gap is closed | N/A until an offline cache exists |
| Realtime reconnection budget | **< 2s** after connectivity restored | Not measured; reconnection is entirely the Supabase SDK's default `RealtimeClient` backoff — no KYNZA-authored reconnect logic to tune (`docs/ARCHITECTURE_GLOBAL.md` §2.6), so this target is bounded by the SDK's own defaults, not independently controllable without upstream configuration | DevTools network timeline around a simulated connectivity toggle |

## 3. Optimization Levers (top 3 per metric family, grounded in real code where possible)

**Cold/hot start**: (1) `Firebase.initializeApp()` + `Supabase.initialize()` in `main.dart` run
sequentially before `runApp()` — parallelizing independent initializations (e.g. `Hive.initFlutter()`
alongside Firebase init) is a real, low-risk lever not currently applied. (2) `const` constructors
— already enforced project-wide via the `prefer_const_constructors` lint (`docs/PRODUCTION_CHECKLIST.md`,
confirmed `flutter analyze` clean). (3) Defer non-critical work (e.g. `CrashReportingService.init()`)
until after first frame where safe.

**Navigation**: (1) The 320ms `_fadeRoute()` transition (already the standard) is the main lever
— any further reduction would be a deliberate product decision to shave 20ms off `AppDurations.pageTransition`,
not a code-quality fix. (2) `KynzaAnimations.fadeSlideIn()`/`.scaleIn()` are already GPU-cheap
(`Opacity`/`Transform`, no `CustomPainter`) per `docs/ANIMATIONS_GUIDE.md` §4.

**Lists**: `ListView.builder` is already the confirmed pattern for every high-volume list
(bookings, invoices, audit log, notifications, search results — `docs/PRODUCTION_CHECKLIST.md`'s
own prior audit) — this lever is already applied, not a gap.

**Images**: `CachedNetworkImage` is confirmed the only image-loading path (`KynzaAvatar` wraps it
internally, zero raw `Image.network` calls anywhere per the existing checklist audit) — already
applied. Category images (Part 8, once populated) should be pre-optimized (WebP/compressed PNG)
before bundling, per `docs/ASSETS_GUIDE.md` §6.

**Offline load time**: the only real lever is building the outbox/local-cache system described as
a gap in `docs/OFFLINE_STRATEGY.md` — there is no smaller optimization available while that
system doesn't exist.

## 4. Contraintes & Edge Cases

- The 320ms-vs-300ms navigation transition gap is the only metric where a real, measured
  (well, token-defined) current value slightly exceeds its target — every other "current
  baseline" cell is honestly marked "not measured" rather than estimated, because estimating
  without profiling data would be fabrication.
- BLE/NFC and offline-load targets are structurally unmeetable today, not narrowly missed — they
  depend on features/infrastructure that don't exist yet, tracked as roadmap items in
  `docs/PRODUCTION_CHECKLIST.md`, not "needs tuning" performance work.

## 5. Sécurité

N/A.

## 6. Performance

This document IS the performance section.

## 7. Stratégie de tests

No automated performance regression tests exist (no `flutter drive`/integration-test-based
frame-timing assertions found in this pass). Recommended: an integration test asserting the
`_fadeRoute()` transition completes within a bounded time window on CI, as a basic regression
guard, once CI exists (§ M2 in `docs/security/SECURITY_ENTERPRISE.md` — no CI currently exists at
all, a prerequisite for any automated performance gate).

## 8. Documentation associée

- `docs/ANIMATIONS_GUIDE.md` — real duration/curve tokens referenced throughout.
- `docs/OFFLINE_STRATEGY.md` — the offline-load-time gap in full detail.
- `docs/ARCHITECTURE_GLOBAL.md` §2.6 — Realtime reconnection architecture.
- `docs/PRODUCTION_CHECKLIST.md` — no-CI gap and offline gap both tracked there.

## 9. Critères d'acceptation

- [x] Every metric has a numeric target, not a qualitative one.
- [x] Battery/BLE scanning constraint explicitly cross-referenced with the real finding that no
  BLE/NFC code exists — not assumed present per the original brief's `TransportDetector` reference
  (which was already confirmed nonexistent in Phase A).
- [x] No "current baseline" value is invented — every unmeasured metric says so explicitly.

## 10. Livrables

- `docs/PERFORMANCE_TARGETS.md` (this file)
