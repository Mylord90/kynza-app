# KYNZA — Design System

> Part 10. New file at this path (didn't exist before). Seeded from the real, current
> `lib/core/constants/*.dart` token files — not from `docs/ai/skills/kynza-uiux-design-system.md`
> verbatim, because that skill file's code examples have drifted from real code in several
> verifiable places (noted inline below). The skill file remains the AI-agent-facing companion
> doc and is cross-linked, not replaced. Verified 2026-07-03.

## 1. Objectifs

The single source of truth for every visual token and shared component's states, so a new screen
never hand-picks a color/spacing/radius value or reinvents a component that already exists.

## 2. Foundation Tokens (real, `lib/core/constants/`)

### 2.1 Colors (`app_colors.dart`)

Dark Luxury palette — **dark-only in the real codebase**; the skill doc's `*Light` color set
(`backgroundLight`, `primaryLight`, etc.) does **not exist in code** — there is no light theme
today, despite the skill doc showing one as if implemented. Do not build a light-theme toggle
assuming those tokens exist.

| Token | Value | Usage |
|---|---|---|
| `background` | `#09090B` | App background (80% of visual weight, per the skill doc's 80/15/5 rule) |
| `surface` | `#18181B` | Cards, sheets, elevated surfaces |
| `surfaceVariant` | `#27272A` | Skeleton base, secondary surfaces |
| `border` | `#3F3F46` | Default card/input border |
| `primary` | `#EAB308` | Gold accent — CTAs, selections, prices only (5% rule) |
| `primaryVariant` | `#CA8A04` | Gold gradient end-stop |
| `primaryGlow` | `#EAB308` at 10% alpha | Selected-state glow shadow |
| `textPrimary` | `#FAFAFA` | Primary text |
| `textSecondary` | `#A1A1AA` | Secondary/muted text |
| `textMuted` | `#52525B` | Disabled/placeholder text |
| `success`/`error`/`warning`/`info` | `#22C55E`/`#EF4444`/`#F97316`/`#3B82F6` | + matching `*Bg` variants at ~12% alpha for toast/badge backgrounds |
| `goldGradient` | `primary → primaryVariant`, 135°-ish rotation | Primary button fill |
| `loaderGradientColors` | `goldLight/goldCore/primary/amberDeep` | `KynzaLoader`'s "Orbite Dorée" radial gradient — not in the skill doc at all, real-code-only addition |

### 2.2 Typography (`app_typography.dart`)

Real font families: **Plus Jakarta Sans** (`fontUI`, all UI text) and **JetBrains Mono**
(`fontMono`, monetary/code/timestamp values with `FontFeature.tabularFigures()` so digits align
in columns) — both bundled locally as variable fonts (no network fetch, offline-first, R13).

The real scale is significantly richer than the skill doc's 6-style table — it has been extended
(per project history, "Typography system extended 2026-07-01") while keeping the original 9
styles unchanged for backward compatibility with ~130 existing files:

| Original (unchanged) | Size/weight | Extended (additive) | Size/weight |
|---|---|---|---|
| `displayLarge` | 32px w900 | `displayMedium` | 28px w700 |
| `h1` | 24px w700 | `headlineLarge`/`Medium`/`Small` | 24/22/20px w700/w600/w600 |
| `h2` | 18px w600 | `titleLarge`/`Medium`/`Small` | 18/16/14px w600/w500/w500 |
| `h3` | 15px w500 | `bodyLarge` | 16px w400 |
| `body` | 14px w400, 1.65 line-height | `bodyMedium` (= `body`) | — |
| `bodySmall` | 12px w400 | `labelLarge`/`Medium`/`Small` | 14/12/10px |
| `button` | 14px w600 | `amountLarge` | 28px w800 mono |
| `label` | 11px w700, +1.5 letter-spacing | `amountLabel` | 14px w500 mono |
| `amount`/`amountMd`/`amountSm` | 24/18/14px w800/w700/w600 mono | `monoBold` | 13px w700 mono |
| `mono` | 13px w400 mono | | |

### 2.3 Spacing scale — 8pt grid (`app_spacing.dart`)

`xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48` — matches the brief's requested
4/8/12/16/24/32/48 scale exactly. **Correction to the skill doc**: `AppSpacing` in real code holds
*only* these 7 spacing values — the skill doc's `radiusCard`/`radiusButton`/`heightButton` etc.
are **not** on `AppSpacing`; they live in the separate `AppRadius` class (§2.4) and as literal
per-component defaults (e.g. `KynzaButton.height = 52`, not 48 as the skill doc states).

### 2.4 Corner radii scale (`app_radius.dart` — real, not in the skill doc at all)

| Token | Value | Usage |
|---|---|---|
| `xs` | 4 | Tight elements (badges) |
| `sm` | 6 | Small chips |
| `md` | 10 | — |
| `lg` | 14 | — |
| `xl` | 16 | — |
| `xxl` | 20 | — |
| `button` | 12 | All `KynzaButton` variants |
| `card` | 16 | `KynzaCard` |
| `sheet` | 24 | Bottom sheets (top corners only) |
| `pill` | 9999 | Fully rounded (badges, chips) |

Each has a matching `_` suffix constant returning a pre-built `BorderRadius.circular(...)` (e.g.
`AppRadius.card_`), used directly in `BoxDecoration.borderRadius`.

### 2.5 Elevation / shadow tokens (`app_shadows.dart` — solid shadow only, no blur filters)

```dart
goldGlow  = BoxShadow(color: primaryGlow, blurRadius: 24, offset: Offset(0,4))
card      = BoxShadow(color: #14000000, blurRadius: 8,  offset: Offset(0,2))
elevated  = BoxShadow(color: #1F000000, blurRadius: 16, offset: Offset(0,4))
```

**Nuance vs. the skill doc's blanket "no BoxShadow on cards" claim**: real `KynzaCard`
(`lib/shared/widgets/kynza_card.dart`) uses **border-only** elevation for its default state
(matching the skill doc's rule), but *does* apply `AppShadows.goldGlow` when `isFeatured: true`
and a custom gold-tinted glow when `isSelected: true`. `BoxShadow` (a cheap, local blur — not a
compositing-wide `BackdropFilter`) is fine performance-wise; the R13 rule bans `BackdropFilter`
specifically, not all `BoxShadow` use. Border-based elevation is the *default*, not an absolute
rule.

### 2.6 Motion tokens

See `docs/ANIMATIONS_GUIDE.md` (Part 9) for the full `AppDurations`/`AppCurves` reference —
not duplicated here.

## 3. Component Specs

For each: states covered are default / pressed / disabled / loading / error, only where
applicable to that component type.

### 3.1 Buttons (`KynzaButton`, real — 4 variants, correcting the skill doc's 3)

| Variant | Default | Pressed | Disabled | Loading |
|---|---|---|---|---|
| `primary` | `goldGradient` fill, `background`-colored text | `AnimatedScale` to 0.97 (`AppDurations.micro`, 80ms) | `AnimatedOpacity` to 0.5 (`AppDurations.fast`, 120ms) | `KynzaLoaderButton(onGoldBackground: true)` replaces label |
| `secondary` | Transparent fill, 1.5px `primary` border, `primary` text | Same scale/opacity pattern | Same | `KynzaLoaderButton(onGoldBackground: false)` |
| `ghost` | Fully transparent, `textSecondary` text | Same | Same | Same |
| `destructive` | `errorBg` fill, 1px `error` border, `error` text | Same | Same | Same |

Height defaults to **52px** (exceeds the 44×44 minimum tap target, §5). Haptic feedback
(`KynzaHaptics.light()`) fires on every successful tap. Icon slot supported (8px gap before
label). Radius: `AppRadius.button` (12) on all variants.

### 3.2 Cards (`KynzaCard`, real)

Default: `surface` fill, `AppRadius.card_` (16), 1px `border`-colored border, no shadow. Selected:
1.5px `primary` border + gold-tinted glow shadow. Featured: 1.5px `primary` border +
`AppShadows.goldGlow`. Pressed (only if `onTap` provided): `AnimatedScale` to 0.98
(`AppDurations.micro`). Padding defaults to `AppSpacing.lg` (16), overridable.

### 3.3 Dialogs (`KynzaConfirmDialog`, real file confirmed)

Used for every destructive action (R15 — `KynzaButtonVariant.destructive` triggers a confirm
dialog automatically per the skill doc's rule, except the Staff "Confirmer arrivée" button, which
deliberately stays `primary` to avoid friction on a high-frequency action).

### 3.4 Bottom sheets (`KynzaBottomSheet`, real file confirmed; spec per skill doc, not
independently re-verified line-by-line in this pass)

`surface` background, `AppRadius.sheet` (24) top corners only, max height 85% of screen, 36×4dp
drag handle always visible at the top, `isScrollControlled: true`.

### 3.5 Snackbars / Toasts (`KynzaToast`, real file confirmed)

4 levels: success (green, auto-dismiss ~2s), error (red, **no auto-dismiss**, always includes a
retry affordance, never shows an HTTP code or raw exception text — cross-references
`docs/ai/skills/kynza-payments-leapa.md` §8's anti-stress messaging rule), warning (orange,
~3s), info (blue, ~2s).

### 3.6 Chart theming (`fl_chart` → Gold/Surface palette mapping)

Not a dedicated theming class found in code — proposed mapping for consistency, using only
existing real tokens:

| Chart element | Token |
|---|---|
| Primary data series | `AppColors.primary` (gold) |
| Secondary/comparison series | `AppColors.info` (blue) |
| Grid lines | `AppColors.border` at reduced opacity |
| Axis labels | `AppTypography.labelSmall` |
| Tooltip background | `AppColors.surfaceVariant` |
| Positive delta | `AppColors.success` |
| Negative delta | `AppColors.error` |

### 3.7 Data tables (staff/commission lists)

No dedicated `KynzaDataTable` widget exists. Per `docs/PRODUCTION_CHECKLIST.md`'s own audit: high-
volume lists (bookings, invoices, audit log, notifications, search results) use
`ListView.builder`; smaller bounded admin lists (team roster, commission rows, filter chips)
use `Column` + `for` inside an outer scrollable — both are acceptable at this app's current
scale, per that audit.

### 3.8 Form fields (`KynzaTextField`, `KynzaPhoneField`, `KynzaPasswordField`, `KynzaDropdown`
— all real files confirmed)

Height convention (skill doc, not independently re-verified against source in this pass):
~52px input height. Validation error state: `error`-colored border + inline error text below the
field, per `Validators` (`lib/core/utils/validators.dart`, real, covered by existing tests —
`test/widget_test.dart`'s `Validators` test group).

## 4. Accessibility

- **Contrast ratios** (WCAG AA requires ≥4.5:1 for normal text, ≥3:1 for large text/UI
  components), hand-computed via the standard relative-luminance formula against the real token
  hex values. **These are manual calculations, not verified with an automated contrast-checker
  tool** — treat as a reasonable approximation to confirm with a real tool
  (e.g. WebAIM's contrast checker) before citing them as a compliance guarantee:
  - `textPrimary` (`#FAFAFA`) on `background` (`#09090B`): **≈19.1:1** — passes AAA.
  - `textSecondary` (`#A1A1AA`) on `background`: **≈7.8:1** — passes AA comfortably; borderline
    passes AAA (7:1 threshold).
  - `primary` gold (`#EAB308`) on `background` (`#09090B`) — used for `amount`/link-style text,
    and equivalently `background`-colored text on a `primary` gold fill (the primary button's
    text-on-gold case, same pair inverted): **≈10.4:1** — passes AAA.
  - `textSecondary` on `surface` (`#18181B`): **≈6.9:1** — passes AA comfortably, but **does
    NOT clear the 7:1 AAA threshold** — worth knowing if any screen relies on `textSecondary`
    over `surface` for body text and wants an AAA guarantee, it would need `textPrimary` instead.
- **Minimum tap target**: `KynzaButton`'s real default height (52px) exceeds the 44×44 minimum.
  Icon-only tap targets (e.g. nav bar items) were not individually audited for 44×44 compliance
  in this pass — flagged as unverified, not confirmed compliant.
- **Semantic labels for screen readers**: `KynzaLoader` accepts an optional `semanticLabel`
  parameter (confirmed, `docs/LOADER_GUIDE.md`). Broader `Semantics`/`excludeSemantics` usage
  across other shared widgets was not audited component-by-component in this pass.
- **Dynamic text scaling**: no explicit `textScaler` clamping or resistance strategy was found in
  this pass — large system font-size settings may affect fixed-height components (e.g.
  `KynzaButton`'s 52px height with a longer label) unpredictably. Flagged as an unverified gap,
  not confirmed either way.
- **Reduced motion**: `KynzaBottomNav` explicitly checks `MediaQuery.of(context).disableAnimations`
  (verified in source) — the one confirmed reduced-motion-aware component found in this pass.
  Other animated components were not individually audited for the same check.

## 5. Contraintes & Edge Cases

Every "not independently re-verified in this pass" flag above is intentional — per the same
skill-doc-drift pattern already established in Parts 2/6/9 of this documentation effort, claims
from `docs/ai/skills/kynza-uiux-design-system.md` are cross-referenced but not treated as ground
truth without checking the real widget source, and where that check wasn't performed in this
pass, it's said so explicitly rather than silently inherited as fact.

## 6. Sécurité

N/A — pure presentation layer.

## 7. Performance

See `docs/ANIMATIONS_GUIDE.md` §4 for the GPU/RepaintBoundary budget discussion.

## 8. Stratégie de tests

`test/widget_test.dart` covers `KynzaButton`'s loading-state spinner swap and `Validators`. No
golden-image tests exist for color/contrast regression. Recommended: a golden test per component
variant (button ×4, card ×3 states) to catch accidental token drift.

## 9. Documentation associée

- `docs/ai/skills/kynza-uiux-design-system.md` — AI-agent-facing companion, left as-is,
  cross-linked with corrections noted above rather than edited (it's outside this pass's file
  ownership).
- `docs/LOADER_GUIDE.md` — full `KynzaLoader` reference.
- `docs/ANIMATIONS_GUIDE.md` — motion tokens.
- `docs/ASSETS_GUIDE.md` — icon/illustration asset conventions referenced by components.

## 10. Critères d'acceptation

- [x] Every component spec lists all interactive states applicable to that component type.
- [x] Contrast ratios computed and stated numerically for gold-on-dark and text-on-dark pairs —
  all 4 pairs checked pass WCAG AA; 2 of 4 clearly pass AAA, 1 is borderline, 1 (`textSecondary`
  on `surface`) passes AA but not AAA — reported honestly rather than rounded up.
- [x] Discrepancies between the skill doc and real code are corrected and explicitly noted
  (light theme doesn't exist; `KynzaButton` has 4 variants not 3; `AppSpacing` doesn't hold radii;
  `KynzaCard` isn't shadow-free in all states).

## 11. Livrables

- `docs/DESIGN_SYSTEM.md` (this file, new)
