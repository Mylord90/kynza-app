# UI_AUDIT.md — Phase A (Premium UI/UX)

Audit performed before any Phase A code changes, per the AGENT.md protocol
(audit existing files before writing code). Findings below reflect the
state of `lib/` at the start of Phase A — most of the Phase A checklist
already existed from prior phases; this audit's job was to find the real
gaps rather than rebuild what's already there.

## What already existed (no rework needed)

| Area | State | Evidence |
|---|---|---|
| Haptics | `KynzaHaptics` (`lib/core/utils/haptics.dart`) — light/medium/success/error/warning, already wired into `KynzaButton` and `KynzaCard` | 14 call sites before Phase A |
| Skeletons | Generic `KynzaSkeleton` shimmer bar, used across ~20 screens | `lib/shared/widgets/kynza_skeleton.dart` |
| Empty states | `KynzaEmptyState` with **mandatory CTA**, deployed on 35+ screens | `lib/shared/widgets/kynza_empty_state.dart` |
| Offline banner | `KynzaOfflineBanner`, non-blocking, auto-sync confirmation | deployed on 14 screens pre-Phase A |
| Bottom sheets | `showKynzaBottomSheet` — 85% max height, rounded top, drag handle | 18 call sites |
| `BackdropFilter` | Zero occurrences (perf rule already enforced, see `app_shadows.dart` comment) | confirmed via grep |
| `CircularProgressIndicator` | Exactly one occurrence, inside the `KynzaSpinner` wrapper itself (not a bare spinner on a data screen) | confirmed via grep |

**Priority: P2 (already done).** No action taken — listed here so a future
agent doesn't recreate `HapticService`, `KynzaEmptyState`, etc. under a new
name.

## Real gaps found and fixed in Phase A

### P0 — Bug: `_StaffPerformanceLoader` rendered without a Scaffold
`lib/core/router/app_router.dart`'s route for `/staff/performance` (used by
notification deep links) returned `MyPerformanceScreen` directly with no
`Scaffold`/`AppBar`/offline banner — only the loading/error/null branches
had a `Scaffold`. Reached via the home tab it's fine (the parent screen
supplies the Scaffold), but a direct deep link would have shown a bare
`ListView` with no app bar and no offline banner. **Fixed**: the loader's
`data` branch now wraps `MyPerformanceScreen` in its own `Scaffold` +
`AppBar` + `KynzaOfflineBanner`.

### P0 — Orphaned Hero tag
`salon_detail_screen.dart` had a `Hero(tag: 'salon-cover-${salon.id}')`
around the cover image, but `SalonCard` (the list-side widget) had no
matching `Hero` — so the shared-element animation never actually fired.
**Fixed**: added the matching `Hero` to `salon_card.dart`. Also added a new
`staff-avatar-${staff.id}` Hero pair between `StaffCardDetailed` (list) and
`StaffDetailScreen` (detail) — previously zero staff Hero animations existed.

### P1 — New Phase 4-6/Advanced screens missing offline banner + pull-to-refresh
Screens added in the most recent commits (billing, team/commissions,
search, loyalty QR/scan, staff detail) were built before the offline
banner/pull-to-refresh convention had spread everywhere. Added
`KynzaOfflineBanner` + `RefreshIndicator` (where they render a list) to:
`billing_screen.dart`, `subscription_plans_screen.dart`,
`invoice_history_screen.dart`, `commission_screen.dart`,
`advanced_search_screen.dart`, `loyalty_qr_screen.dart`,
`loyalty_scan_screen.dart` (banner overlaid on the camera view, non-blocking),
`staff_detail_screen.dart`. Also added pull-to-refresh to `staff_list_screen.dart`
and `services_list_screen.dart`, which had the banner but not refresh.

### P1 — Single flat fade transition on all ~60 routes
`_fadeRoute` in `app_router.dart` used a linear `FadeTransition` only.
**Fixed**: added `AppCurves` (new file, `decelerate`/`accelerate`/`spring`/
`sharp`/`standard`) and a dedicated `AppDurations.pageTransition` (320ms),
then upgraded `_fadeRoute` to a fade + short rightward slide-settle with
`AppCurves.decelerate`. Single point of change, affects the whole app.

### P2 — No named skeleton variants
Every loading state used the generic `KynzaSkeleton(height: X)` bar — fine,
but visually generic. Added 7 named, composed variants in
`lib/shared/widgets/kynza_card_skeletons.dart` (`KynzaBookingCardSkeleton`,
`KynzaServiceCardSkeleton`, `KynzaStaffCardSkeleton`,
`KynzaAnalyticsCardSkeleton`, `KynzaNotificationItemSkeleton`,
`KynzaReviewCardSkeleton`, `KynzaLoyaltyCardSkeleton`), each built from the
existing `KynzaSkeleton` bar so the shimmer stays consistent. Wired into:
`notifications_screen.dart`, `owner_reviews_screen.dart`,
`salon_reviews_tab.dart`, `services_list_screen.dart`,
`staff_list_screen.dart`, `invoice_history_screen.dart`,
`commission_screen.dart`.

**Not wired yet (follow-up, not done in this pass):** `loyalty_card_widget.dart`
and `client_loyalty_screen.dart` still use a flat `KynzaSkeleton(height: 220)`.
Swapping to `KynzaLoyaltyCardSkeleton` (which is shorter) without first
checking the real loyalty card's rendered height risks a layout jump when
the real content replaces the skeleton — left as-is rather than guess.
Search results (`advanced_search_screen.dart`) also still use the generic
bar — none of the 7 named shapes matches its avatar+title+subtitle+trailing
layout closely enough to be worth a one-off 8th variant in this pass.

### P2 — No selection haptic on chip/grid pickers
`ServiceCategoryChip` and `TimeSlotGrid` had no haptic feedback at all
(unlike `KynzaButton`/`KynzaCard`, which already call `KynzaHaptics.light()`).
Added `KynzaHaptics.selection()` (new method, `HapticFeedback.selectionClick()`)
and wired it into both.

### P2 — Reusable entrance animations
Added `lib/core/animations/kynza_animations.dart` (`KynzaAnimations.fadeSlideIn`,
`.scaleIn`, `.shimmerPulse`) built on the existing `AppDurations`/new
`AppCurves` — not yet adopted by any screen in this pass (no screen
currently needs a one-off entrance animation beyond what skeletons/page
transitions already cover); available for Phase J's dashboard work.

## Not done / explicitly out of scope for this pass

- **SVG/Lottie illustrations for empty states** — `KynzaEmptyState` accepts
  an `svgAsset` param but no illustration assets exist in `assets/`.
  Fabricating placeholder SVGs wasn't attempted; this needs real design
  assets, not code.
- **~100 screens not yet on `AppLocalizations`** — pre-existing tracked debt
  (`AGENT.md`), unrelated to Phase A's animation/feedback scope.
- **Full skeleton-variant coverage** — see "Not wired yet" above.