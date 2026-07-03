# Phase 8 — Accessibility & Performance Pass

> The highest-regression-risk phase in the Enterprise Hardening pass — it touches existing
> screens directly. Executed in 4 small batches, each with its own `flutter analyze`/`flutter
> test` run and its own scoped commit, per this phase's own rule (not just a single check at the
> end). Every number below is measured, not estimated — computed contrast ratios, real grep
> counts, and actual code excerpts, not impressions.

## 1. Scope decision made before starting

A full research pass (not this document — a prior investigation) surfaced far more findings
than could safely be fixed in small, low-regression-risk batches in one pass. Per Mylord's
explicit decision, this phase:

- **Fixed**: real, well-scoped, low-code-risk items (contrast, one tap-target violation, 10
  missing tooltips, 2 genuinely-unbounded render paths, 2 unnecessary whole-object provider
  watches).
- **Documented, not fixed**: 8 repository methods that stream/fetch entire tables unbounded,
  several of which are then filtered client-side by date — blindly adding `.limit()`/`.range()`
  without tracing each consuming screen's exact filtering semantics risks a silent correctness
  regression, which is a worse outcome than leaving a known, evidenced performance gap for a
  dedicated future pass. See §5.

## 2. Accessibility

### 2.1 Contrast — real WCAG ratios computed (relative-luminance formula, not estimated)

| Pair | Ratio | AA normal (4.5:1) | AA large (3:1) |
|---|---|---|---|
| textPrimary #FAFAFA on background #09090B | 19.06:1 | PASS | PASS |
| textPrimary #FAFAFA on surface #18181B | 16.97:1 | PASS | PASS |
| textSecondary #A1A1AA on background #09090B | 7.76:1 | PASS | PASS |
| textSecondary #A1A1AA on surface #18181B | 6.91:1 | PASS | PASS |
| **textMuted (old) #52525B on surfaceVariant #27272A** (hint text) | **1.93:1** | **FAIL** | **FAIL** |
| **textMuted (old) #52525B on background #09090B** | **2.57:1** | **FAIL** | **FAIL** |
| **textMuted (new) #8E8E96 on surfaceVariant #27272A** | **4.58:1** | **PASS** | PASS |
| **textMuted (new) #8E8E96 on background #09090B** | **6.12:1** | **PASS** | PASS |
| background #09090B on primary #EAB308 (gold button text) | 10.37:1 | PASS | PASS |
| textPrimary #FAFAFA on error #EF4444 (`colorScheme.onError`) | 3.61:1 | FAIL | PASS |
| primary #EAB308 on background #09090B (gold accent text) | 10.37:1 | PASS | PASS |
| success #22C55E on background #09090B | 8.73:1 | PASS | PASS |
| error #EF4444 on background #09090B | 5.29:1 | PASS | PASS |
| border #3F3F46 on background #09090B (non-text UI outline) | 1.91:1 | n/a (non-text) | n/a |

**Fixed**: `textMuted` — was failing WCAG AA badly on every input field's hint text and every
muted label app-wide (1.93:1 / 2.57:1). Lightened to `#8E8E96` (4.58:1 / 6.12:1, both pass) while
staying one visible step darker than `textSecondary` — a real, app-wide contrast bug closed, not
a marginal tweak (`lib/core/constants/app_colors.dart`, batch 1 commit).

**Not fixed — flagged, needs a product decision**: `textPrimary` (#FAFAFA) on `error` (#EF4444),
used for `colorScheme.onError`, is 3.61:1 — fails the 4.5:1 threshold for normal-size text but
passes the 3:1 threshold for large text (≥18pt, or ≥14pt bold). This wasn't fixed because the
correct fix depends on where `onError` actually renders in practice (large bold text vs. small
body text) — a repo-wide grep for every place Flutter's Material widgets consume
`colorScheme.onError` wasn't performed as part of this pass; flagged here rather than guessed at.

`border` (#3F3F46) at 1.91:1 against background is **not a text-contrast failure** — WCAG's
relevant guideline for non-text UI component outlines (1.4.11) has a lower 3:1 threshold and only
applies to interactive-component boundaries, not every decorative border; not evaluated further
here since it would need a per-component audit to say anything precise.

### 2.2 Semantic labels / tooltips

**Before**: explicit `Semantics(` usage existed in exactly 2 places app-wide (`kynza_bottom_nav.dart`,
`kynza_loader.dart`) — essentially greenfield, not an established pattern. 47 `IconButton(` call
sites existed across 28 files; 38 had no `tooltip:` (which doubles as the accessibility label
when no explicit `Semantics` wraps the button).

**Fixed (10 highest-traffic, batch 2)**: notification bell badge (shown on all 3 home screens),
every prev/next chevron pair (4 separate files — home_owner, home_staff, dashboard team-analytics
tab, commission screen, booking calendar widget — 5 files, 6 pairs total once counted precisely),
notification banner dismiss button, notifications settings gear, search filter icon, salon-detail
share icon, owner confidential-mode toggle + salon-share icon, and (found while touching the
churn-risk section in batch 3) the per-client win-back share button.

**Not fixed — remaining backlog**: 28 more icon buttons without tooltips exist across the other
~90 screens not touched in this pass. Not attempted here — the highest-traffic, most-reused
components were prioritized over a mechanical sweep of every remaining one-off admin/settings
screen, to keep this phase's regression surface proportionate to its risk label.

### 2.3 Tap targets (WCAG 2.5.5, 44×44 minimum)

**One real violation found and fixed**: `feature_flag_screen.dart`'s override-reset button had
`padding: EdgeInsets.zero` + `constraints: const BoxConstraints()`, stripping its tap target to
~18×18px (matching its 18px icon exactly, with zero surrounding hit area). Fixed by removing both
overrides — the default `IconButton` 48×48 minimum now applies, icon still renders at 18px inside
it.

**Everything else checked, no violation found**: no other `IconButton` anywhere in `lib/` sets an
`iconSize:` or `constraints:` override (confirmed by grep — zero other matches). The bottom nav
(`kynza_bottom_nav.dart`) was independently measured: icon (22–26px) + label + spacing ≈ 51px
tall tap zone per item, passing the 44px floor.

### 2.4 Dynamic text scaling (200% OS scale)

**Confirmed unclamped** (correct — clamping OS text scale is itself an accessibility
anti-pattern, so this is not something to "fix"): no `MediaQuery`/`textScaler`/`textScaleFactor`
override exists anywhere in `lib/main.dart` or elsewhere in the app. The OS accessibility
text-scale setting flows through to every `Text` widget unmodified.

**Not independently visually verified at 200%** in this environment — there is no attached
Android/iOS device or emulator (`flutter devices` shows only Windows desktop and
Chrome/Edge web targets; no `windows/`/`macos`/`linux` platform folder is even configured in this
project, so `flutter run -d windows` isn't available without first running `flutter create
--platforms=windows .`). Rendering at 200% scale on a Windows/Chrome target would not accurately
represent real mobile OS text-scaling/clipping behavior even if attempted, so no fake "tested at
200%" claim is made here. Flagged as a real gap requiring either a connected Android
emulator/device or accepting web/desktop as an imperfect proxy — a decision for whoever next has
device access, not resolved in this pass.

### 2.5 Keyboard navigation

**Not independently tested** — same device-availability constraint as §2.4 (no
keyboard-capable device/emulator attached). What can be said from static analysis: no widget in
`lib/` overrides Flutter's default `Focus`/`FocusTraversalGroup` behavior or intercepts `Tab`/
arrow-key events in a way that would break standard focus traversal (no custom `RawKeyboardListener`/
`Focus(onKeyEvent:...)` found outside of standard `TextField`/`KynzaButton`-style widgets, which
inherit correct default behavior from Material). This is a reasonable basis for *not expecting* a
problem, but is explicitly not the same as having verified it — flagged honestly rather than
asserted as tested.

## 3. Performance

### 3.1 The 5 named screens — what was found, what changed, real frame-timing status

**No live Flutter DevTools timeline/frame-timing capture was performed** — this requires a
connected device/emulator (§2.4's constraint applies identically here) or the web target with the
important caveat that web rendering characteristics (and several mobile-only plugins —
`firebase_messaging`, `mobile_scanner`) don't transfer meaningfully to real device jank analysis.
No frame-timing numbers are reported as "measured" for this reason — reporting fabricated
frame-time numbers would violate this pass's own rule against unverifiable claims more than
reporting nothing. What *was* measured is static: actual `ListView`/`Column` render-boundedness
via direct code reading (not guessed), reported per screen below.

| Screen | Render pattern found | Action |
|---|---|---|
| **Dashboard analytics** (`advanced_dashboard_screen.dart`) | Overview/Clients/Team/Forecast tabs use plain `ListView`, not `.builder` — but the *interesting* content (KPI grid, top-clients list) is small/fixed or already capped (5) at the provider level. The one genuine unbounded loop (churn-risk clients) was fixed (§3.2). Team performance loop is bounded by staff-roster size (inherently small) — left as-is. | Fixed the one real risk; documented why the others don't need the same treatment |
| **Booking list** (`client_bookings_screen.dart`) | UI-side already correct: both loading and real-data paths use `ListView.builder`. The real risk is upstream — `getClientBookings` streams the client's entire booking history unbounded, filtered to upcoming/past only in Dart after full download | UI unchanged (already correct); data-layer gap documented in §5, not fixed |
| **Search** (`advanced_search_screen.dart`) | Real-data path used a plain `ListView` with two `for` loops (salons + services) — genuinely unbounded render | **Fixed** — flattened into one `ListView.builder` over a combined header/tile row list (§3.2) |
| **ProxiPay flow** (`proxipay_scan_screen.dart`/`proxipay_qr_screen.dart`) | No lists at all (phase-based `switch` UI); its one realtime subscription already uses `.limit(1)` — the **only** place in the whole codebase where a stream is capped | Already correct, no action needed |
| **Notifications** (`notifications_screen.dart`) | Best-behaved of the five: `ListView.builder` throughout, real UI-level pagination (`_limit`/20-per-page "load more"). But cosmetic — `getNotifications` fetches the user's entire notification history unbounded first, only applying `.take(limit)` in Dart afterward, so growing the UI limit doesn't reduce what's already downloaded | UI unchanged (already correct pattern); data-layer gap documented in §5 |

### 3.2 Fixes applied

- **`AdvancedSearchScreen`**: eager two-section `ListView` (salons + services, `for` loops) →
  `ListView.builder` over a flattened `_SearchListRow` list (header or tile per index). Batch 3.
- **Dashboard `_ChurnRiskSection`**: genuinely unbounded (one `KynzaCard` per at-risk client, no
  cap) — but nested inside the tab's outer plain `ListView`, so a nested `ListView.builder` would
  need `shrinkWrap: true`, which forces Flutter to lay out every child anyway and would **not**
  actually bound the render cost (a technical point worth remembering for future similar fixes —
  `.builder` inside a scrollable parent without its own `Sliver`/viewport doesn't give the laziness
  win people expect). Applied a direct display cap instead (25 per risk level, "+N more"
  indicator) — this genuinely bounds the widget count regardless of how large the underlying
  list grows. Batch 3.
- **`notifications_screen.dart` / `client_bookings_screen.dart`**: both watched
  `currentUserProfileProvider` in full but only ever used `.id` — rescoped to
  `.select((async) => async.valueOrNull?.id)`, so an unrelated profile field changing elsewhere
  (avatar upload, name edit) no longer rebuilds either screen. Batch 4.

### 3.3 Not fixed — left as multi-provider `build()` watches

`_OverviewTab` (dashboard, 8 unscoped `ref.watch` calls) and `AdvancedSearchScreen`'s `build()`
(4 unscoped watches) were reviewed and left untouched — every value watched in both is genuinely
used across the whole screen (not a single-field extraction opportunity like §3.2's two fixes),
so a forced `.select()` split there would mean restructuring multiple sub-widgets for a much
smaller, harder-to-verify win, on the exact two screens named as highest-traffic. Not worth the
regression surface in this pass.

### 3.4 Image caching — checked, already clean, no action needed

`CachedNetworkImage` is used consistently for every user-facing photo surface found (avatars,
salon card thumbnails, salon detail hero image, media gallery — 4 files, 5 occurrences). Zero
raw `Image.network(` usage exists anywhere in `lib/`. Nothing to fix here.

## 4. Regression check per batch

| Batch | Change | `flutter analyze` | `flutter test` |
|---|---|---|---|
| 1 | textMuted contrast fix | 0 issues | 295/295 |
| 2 | Tap-target fix + 10 tooltips | 0 issues | 295/295 |
| 3 | Search/dashboard unbounded-render fixes | 0 issues | 295/295 |
| 4 | 2 `.select()` scoping fixes | 0 issues | 295/295 |

Test count stayed at 295 throughout this phase (no new tests were added — every change here is a
UI/perf fix to existing screens, not new business logic requiring new test coverage; existing
widget/golden tests, where they touch these screens, continued to pass unchanged).

## 5. Documented backlog — the 8 unbounded repository methods (not fixed, why, and what the real fix looks like)

Every one of these fetches an entire table's worth of rows for a filter key (not paginated), most
via a Supabase Realtime `.stream()` with no `.limit()`:

| Method | File | Consumer | Why not blindly fixed |
|---|---|---|---|
| `getClientBookings(clientId)` | `booking_repository_impl.dart` | `client_bookings_screen.dart` | Screen does client-side upcoming/past filtering on the full result; a naive `.limit()` could return the wrong window (e.g. miss a far-future booking) |
| `getSalonBookings(salonId, date)` | same | owner/staff daily views | Filters to a single day in Dart after downloading all-time bookings for the salon |
| `getPractitionerBookings(practitionerId, date)` | same | staff daily views | Same pattern as above |
| `getBookingsInRange` / `getPractitionerBookingsInRange` | same | (not traced to a specific screen in this pass) | No `.range()`/`.limit()` at all; needs its callers identified before capping |
| `getNotifications(userId, {limit})` | `notification_repository_impl.dart` | `notifications_screen.dart` | The `limit` parameter is applied client-side via `.take()` *after* an unbounded fetch — cosmetic pagination only |
| `watchUnreadCount(userId)` | same | unread badge (all 3 home screens) | Streams every notification row just to count unread ones |
| `getContacts(salonId)` | `marketing_repository_impl.dart` | client-contacts screen | Unbounded stream of every contact ever added |
| `getPromotions(salonId)` | same | promotions screen | Unbounded stream of every promotion, active or expired, ever created |

**What the real fix looks like** (not attempted here): each of these needs its consuming screen's
exact filtering/display semantics traced individually — e.g. does "upcoming bookings" need a
`.gte('start_time', now)` server-side filter instead of client-side, would that change behavior
if a user's clock is skewed, does the unread-count badge actually need every row or would a
dedicated SQL `count()` RPC (matching the pattern `getBookingsInRange` almost has) serve it
without downloading rows at all. This is real, scoped, valuable follow-up work — but it's a
different phase's worth of careful, screen-by-screen verification, not a one-line `.limit()` add
across 8 call sites in a phase whose own rule is "test green after every batch, not just the
end." Tracked here with enough precision that whoever picks this up next doesn't have to
re-discover it from scratch.

## 6. Acceptance criteria check

- [x] `flutter test` green after every batch commit, not just the final one (§4).
- [x] Contrast ratios are actual computed values (relative-luminance WCAG formula), not estimates
  (§2.1) — including the one that was found failing and got fixed, with before/after numbers.
- [ ] ~~Frame-timing numbers~~ — **not claimed as measured**, honestly, since no
  device/emulator was available in this environment to capture them for real (§3.1). Reporting
  fabricated numbers to satisfy this checkbox would violate this pass's own evidence rule more
  than leaving it honestly unchecked.
