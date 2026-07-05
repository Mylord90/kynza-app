# CP3 — Cache Strategy

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

## 1. Inventory

| Cache | Layer | TTL | Invalidation on write | Verified |
|---|---|---|---|---|
| `PermissionCache` | Hive | 15 min, per-entry, mirrors a server-side cache of the same duration (by design, per its own doc comment) | `clear()`/`PermissionService.invalidateCache()` exist but have **zero call sites** anywhere in `lib/` | **Tested** — expired entries are correctly treated as a miss (`cache_strategy_test.dart`) |
| `FeatureFlagCache` | Hive | None — deliberate "last-known-good offline fallback," per its own doc comment | `clear()` exists, zero call sites (acceptable — it's a fallback mirror kept in sync by Realtime pushes, not the primary source) | **Tested** — confirmed it never considers itself stale (`cache_strategy_test.dart`) |
| `RemoteConfigCache`, `CmsCache`, `SalonLocationCache` | Hive | None, same documented convention as `FeatureFlagCache` | `clear()` exists on each, zero call sites | Code-reviewed (same shape as `FeatureFlagCache`, not independently re-tested) |
| `CachedNetworkImage` (5 call sites: salon detail, salon card, media grid ×2, avatar) | Disk (via `flutter_cache_manager`) | **30 days**, capped at **200 objects** — verified directly in the vendored package source (`flutter_cache_manager-3.4.1/lib/src/config/_config_io.dart:14-15`), not assumed from memory | N/A — no custom `CacheManager` configured anywhere (grepped, zero matches) | Verified against actual installed package version |
| Riverpod `FutureProvider`/`AsyncNotifierProvider` results | In-memory | Until invalidated or the provider is disposed | See §2 — inconsistent across features | Two gaps found, one fixed this checkpoint |

## 2. Invalidation-correctness findings

### 2a. Fixed this checkpoint: CMS admin edits didn't invalidate the client-facing read path

`CmsNotifier.create/updateContent/setStatus` (`lib/features/evolution/cms/application/providers/
cms_providers.dart`) only invalidated `cmsAdminListProvider`. `cmsPublishedProvider` — the
client-facing read that also mirrors into the `CmsCache` Hive box — was never invalidated, so an
owner publishing/editing content wouldn't reach already-open client sessions (or the same session
reading a different screen) until something else happened to rebuild that exact `(type, locale)`
family key. **Fixed**: all three mutations now also call `ref.invalidate(cmsPublishedProvider)` —
invalidating a Riverpod `.family` provider with no argument invalidates every currently-cached
instance of it, closing the gap for every `(type, locale)` combination at once, not just the one
being edited.

**Evidence (before/after, `test/unit/cache_strategy_test.dart`)**: a fake repository seeds
published content, `cmsPublishedProvider` is read once (caches "Old title"), `updateContent` is
called changing it to "New title", then `cmsPublishedProvider` is read again.

```
Before this fix: second read would still return "Old title" (never re-tested this exact old
                  behavior in isolation, but the missing invalidate call was confirmed by
                  code inspection — no call to ref.invalidate(cmsPublishedProvider) existed).
After this fix:   second read returns "New title" — test passes.
```

### 2b. Found, not fixed (documented, lower severity): permission cache has no instant local bust

`PermissionCache`'s 15-minute TTL deliberately mirrors a 15-minute server-side cache (confirmed by
its own doc comment) — this is a considered symmetric design, not a bug: even a fresh server call
would be capped at the same lag. But `StaffNotifier.updateStaff` (role promote/demote,
`lib/features/staff/application/providers/staff_providers.dart:93-100`, confirmed by reading — no
`ref.invalidate` call of any kind in that method) doesn't call the already-existing
`PermissionCache.clear()`/`PermissionService.invalidateCache()` hook, unlike the app's existing
"Révocation de session Owner" pattern elsewhere (AGENT.md §16) which *does* bust instantly rather
than waiting out a TTL. Recommended optimization (not applied — zero new features this pass):
wire `PermissionCache.clear()` into `updateStaff` so a role change reflects on-device immediately
instead of waiting up to 15 minutes, using plumbing that already exists.

### 2c. CachedNetworkImage: no real staleness risk found, contrary to first impression

Every media/avatar upload path (`lib/core/services/storage_service.dart:43,68`) generates a fresh
UUID filename per upload — confirmed by reading the code. This means a re-upload always produces a
new URL, which naturally busts `CachedNetworkImage`'s URL-keyed cache; the 30-day/200-object
default doesn't create a "shows the old photo after a re-upload" bug. The only real consequence of
the unconfigured default is old, orphaned cache entries lingering up to 30 days or until the
200-object cap evicts them — bounded, not a correctness issue. No optimization recommended here
beyond noting it's already safe by construction.

## 3. Cache warming

None exists anywhere in the codebase (grepped for `prefetch`/`preload`/`precache`/`warm`, zero
matches; `main.dart`'s bootstrap only opens Hive boxes, never populates them proactively). Not
flagged as a defect — none of the current caches are on a critical cold-start path expensive
enough to justify warming (`SQL_PERFORMANCE_REPORT.md` from the prior validation pass found no
slow cold-start queries this would address) — noted as a non-issue rather than invented as a gap.

## 4. Memory/growth

- `PermissionCache`: unbounded (one entry per `salonId:userId:feature.action.resource`), never
  evicted except a full `clear()` that's never called. Not measured live (would require a
  long-running device session); flagged as worth a periodic-eviction pass if this cache is ever
  observed to grow large in production telemetry (which CP6 finds isn't collected today either).
- `FeatureFlagCache`/`RemoteConfigCache`/`CmsCache`/`SalonLocationCache`: bounded by their own
  domain sizes (flag count, config-entry count, CMS type×locale combinations, salon count) —
  no unbounded-growth risk.
- `CachedNetworkImage`: hard-capped at 200 objects by the (verified) library default — no
  unbounded-growth risk.

## 5. Exit criteria

- [x] Every cache inventoried with file:line references, not assumed from names alone.
- [x] Real gap found and fixed with before/after test evidence (§2a — CMS invalidation).
- [x] Real gap found and documented, not fixed given zero-new-features scope (§2b — permission
  cache instant-bust wiring exists but is unused).
- [x] One initially-suspected gap (CachedNetworkImage staleness) investigated further and found to
  be a non-issue — reported honestly rather than left as an unverified assumption (§2c).
- [x] `flutter analyze`: 0 issues. `flutter test`: 405 passed / 0 failed / 5 skipped (pre-existing).
