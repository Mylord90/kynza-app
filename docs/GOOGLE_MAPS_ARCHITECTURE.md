# KYNZA — Google Maps Architecture (Scaffold, Inert)

> Phase 7 of the Enterprise Hardening & Production Readiness pass. Full architecture ready,
> **zero live API cost, nothing activated without an explicit key** — every acceptance criterion
> in this phase is about proving what does *not* happen (no network call, no billing account
> needed) as much as what's built.

## 1. Current state (verified before this phase)

- **`feature_google_maps` flag**: already seeded, off, in the draft feature-flags migration
  (`supabase/migrations/20260703140000_feature_flags_registry.sql:16` —
  `is_enabled = false, rollout_percentage = 0`), itself still unapplied to the remote (Rule 8).
- **Zero Maps-related pub dependencies**: confirmed no `google_maps_flutter`, `geocoding`,
  `geolocator`, or `flutter_polyline_points` anywhere in `pubspec.yaml`.
- **`salons.latitude`/`salons.longitude`** columns exist (`DECIMAL(10,8)`/`DECIMAL(11,8)`,
  `20260623200000_salon_full_schema.sql`) and round-trip through `SalonFullModel` and
  `SalonRepositoryImpl`, but **no UI anywhere ever populates them** — the salon creation wizard
  (`SalonLocationStep`) only collects `province`/`commune` (hardcoded dropdowns,
  `BurundiProvinces`) plus a free-text address field. So every salon's coordinates are `null`
  today, in practice, regardless of anything this phase builds.
- **The feature-flags evaluation system itself was unused**: `FeatureFlagRepository.evaluateFlag(key)`
  existed (calls RPC `evaluate_feature_flag`) but had zero call sites anywhere in the app before
  this phase — this Maps scaffold is the **first** real consumer, via the new
  `featureFlagEvaluationProvider` (`lib/features/evolution/feature_flags/application/providers/feature_flag_providers.dart`).

## 2. The double gate

`GoogleMapsFeatureGate` (`lib/features/maps/application/google_maps_feature_gate.dart`) requires
**both**:

1. `Env.googleMapsApiKey.isNotEmpty` — a real key supplied via `--dart-define=GOOGLE_MAPS_API_KEY=...`
   at build time. **Empty by default; no key is committed anywhere in this repo.**
2. `feature_google_maps` evaluating to `true` server-side (the same RPC every other flag uses).

`googleMapsEnabledProvider` checks #1 **first** and short-circuits to `false` without ever
calling Supabase if no key is configured — proven by test
(`test/unit/google_maps_feature_gate_test.dart`: overriding the flag-evaluation provider to throw
if it's ever read, then confirming the gate still resolves to `false` cleanly). This means: even
if someone flips the flag on in the admin screen by mistake, nothing activates without a key
also being supplied at build time, and vice versa.

## 3. The 5 API areas — all gated, all inert

`lib/features/maps/domain/repositories/` (interfaces) + `lib/features/maps/data/repositories/`
(implementations): `PlacesAutocompleteRepository`, `GeocodingRepository` (geocode +
reverse-geocode in one interface — they're the same API, opposite direction),
`DirectionsRepository`, `DistanceMatrixRepository`.

Every implementation follows the same shape:
```dart
Future<Result?> someMethod(...) async {
  if (!await isEnabled()) return null; // or [] — zero network activity
  throw UnimplementedError('... has no SDK wired up yet — see docs/GOOGLE_MAPS_ARCHITECTURE.md');
}
```
**Two independent reasons nothing can ever call Google's servers today**: the gate is off (no
key), *and* even in the hypothetical case it weren't, there is genuinely no `google_maps_flutter`/
Places/Geocoding SDK installed to make the call with — the method would throw
`UnimplementedError` instead. Both properties are proven by test
(`test/unit/maps_repositories_test.dart`), including the second one explicitly (constructing a
repository with a fake `isEnabled: () async => true` and confirming it still throws rather than
silently "succeeding" with fabricated data).

Result models (`lib/features/maps/domain/models/maps_models.dart` — `PlacePrediction`,
`GeocodeResult`, `DirectionsResult`, `DistanceMatrixResult`) are deliberately minimal placeholders,
not modeled after a real Google API response, since no real response has ever been received.
Expect to reshape them once a real key is supplied and the actual SDK is added.

## 4. Offline cache

`SalonLocationCache` (`lib/features/maps/data/salon_location_cache.dart`) — a Hive box
(`kynza_salon_location_cache`, opened in `main.dart`), mirroring `PermissionCache`'s static-class
shape. No TTL (a salon's coordinates don't go stale the way a permission check does). **Currently
a no-op in practice**: since no UI populates `salons.latitude`/`longitude` yet (§1), there's
nothing real to cache — the mechanism is ready, proven correct by test
(`test/unit/salon_location_cache_test.dart`, a real temp-directory Hive box, not mocked), and
will start doing real work automatically the day a salon actually gets coordinates (either
manually or via a future geocoding step on the address field).

## 5. Fallback UX — already the current behavior, not new work

The phase brief requires: "list view instead of map view, manual address entry instead of
autocomplete." Both are **already exactly what happens today**, with zero changes needed:

- `AdvancedSearchScreen` is purely `ListView`/`ListView.builder` — there is no map view anywhere
  to "fall back from." When a real map view is eventually built, it should check
  `googleMapsEnabledProvider` and render the existing list as its `false` branch.
- `SalonLocationStep` (salon creation wizard) already collects address via province/commune
  dropdowns + free text — manual entry, not autocomplete, is the only path that exists. When
  Places Autocomplete is eventually wired up, it should be an *additive* enhancement to this
  step (an optional suggestion list above the existing fields), never a replacement that could
  leave an owner stuck if the gate is off.

No screen was modified in this phase — there was nothing to change to satisfy this requirement,
since the "fallback" state is the only state that has ever existed.

## 6. Marker clustering — architecture documented, implementation stubbed

Not implemented (no key to test against real map tiles yet — implementing pixel-accurate
clustering without being able to render a real `GoogleMap` widget would be guesswork). Documented
choice for when it is:

- **Algorithm**: grid-based clustering (bucket markers into geographic grid cells sized relative
  to the current zoom level, render one aggregate marker per non-empty cell above a
  zoom-dependent threshold) — not a k-means/hierarchical approach, since salon density in any one
  city is low enough (tens to low hundreds, not thousands) that the simpler, cheaper grid method
  is sufficient and avoids a second heavy dependency (e.g. `google_maps_cluster_manager` adds its
  own maintenance/version-compatibility surface on top of `google_maps_flutter` itself).
- **Performance budget**: re-cluster on camera-idle (not on every camera-move frame), targeting
  under 16ms for the clustering pass itself at up to ~500 salons in view (a generous upper bound
  for any single city-scale query) — camera-move frames should never block on clustering math.
- **Data source**: `SalonLocationCache` (§4) as the read-through layer, so a cluster can still
  render approximate pins from cache even during a brief Maps-API hiccup, falling back to "no pin
  for this salon" (not a crash) if neither the live coordinate nor a cached one is available.

## 7. Activation procedure (when a real key is ready to be supplied)

1. Obtain a Google Cloud Maps Platform API key with the required APIs enabled (Places, Geocoding,
   Directions, Distance Matrix, Maps SDK for Android/iOS) — **a billing-account decision, out of
   this phase's authority per Rule 9**, requires Mylord's explicit confirmation.
2. Supply the key via `--dart-define=GOOGLE_MAPS_API_KEY=<key>` at build time — never commit it.
3. Add `google_maps_flutter` (+ the relevant Places/Geocoding/Directions HTTP client, likely via
   direct REST calls rather than a heavy second SDK) to `pubspec.yaml`, verify with a real release
   build (same rigor as every native-dependency addition in this pass — Phase 1's manifest
   re-check, Phase 4/5's `aapt` permission diffs).
4. Replace each repository impl's `throw UnimplementedError(...)` body with the real SDK/HTTP
   call, keeping the `if (!await isEnabled()) return null;` guard exactly as-is.
5. Flip `feature_google_maps.is_enabled = true` for a small rollout percentage first (the existing
   `evaluate_feature_flag` RPC already supports percentage-based rollout — no new mechanism
   needed), verify real usage, then ramp up.
6. Only at that point does §5's clustering implementation become buildable against real tiles.

## 8. Regression check

`flutter analyze` = 0 issues. New tests (`google_maps_feature_gate_test.dart`,
`maps_repositories_test.dart`, `salon_location_cache_test.dart`) all pass. **No Google Cloud
billing account or API key was needed to pass any of this** — the acceptance criterion this
phase cares most about.
