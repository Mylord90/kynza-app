# KYNZA — Assets Architecture

> Part 8. Verified against the real `pubspec.yaml` and `assets/` tree (2026-07-03) — only
> genuinely missing folders were created; nothing already populated was touched.

## 1. Objectifs

A predictable, collision-free home for every non-code asset, so a new icon/illustration/sound
lands in exactly one obvious place and gets declared in `pubspec.yaml` without guesswork.

## 2. Architecture — before/after

**Already existed, untouched**: `assets/icons/` (empty, `.gitkeep` only), `assets/images/`
(empty, `.gitkeep` only), `assets/fonts/` (Plus Jakarta Sans + JetBrains Mono variable fonts,
real files), `assets/branding/` (real: `kynza_logo_full.png`, `kynza_logo_icon_only.png`,
`kynza_logo_master.png`), `assets/branding/splash/` (real: `splash_logo_2x.png`).

**Reconciled, not duplicated**: the brief's requested `logos/` folder is **not created** —
`assets/branding/` already holds every logo asset the app uses (confirmed real files above).
Creating a parallel `logos/` would fragment a folder that's already correctly populated and in
active use (`AppBranding` constants, splash screen, launcher icon generation). Any future logo
variant belongs in `assets/branding/`.

**Newly created (empty, `.gitkeep` placeholders, structural only — no binary assets fabricated,
per the hard rule against inventing content)**:

```
assets/
├── icons/premium/      # NEW subfolder of the existing icons/ — premium/gold-tier icon set,
│                         nested rather than a new top-level `premium_icons/` to avoid
│                         fragmenting the icon namespace (icons/ was already the declared home)
├── flags/               # NEW — language flag icons (fr/en toggle, docs/I18N_GUIDE.md)
├── animations/          # NEW — native Flutter/Rive animation assets (distinct from lottie/)
├── lottie/               # NEW — Lottie JSON animations
├── illustrations/       # NEW — stylized full illustrations (onboarding, empty states' hero art)
├── avatars/             # NEW — default/placeholder avatar images (fallback for KynzaAvatar
│                         when a user/staff/salon has no uploaded photo — real uploads live in
│                         Supabase Storage, never bundled here)
├── categories/          # NEW — category images, matches Part 5's categories.slug 1:1
├── onboarding/          # NEW — onboarding swipe illustrations
├── empty_states/        # NEW — small per-context graphics for KynzaEmptyState
├── sounds/               # NEW — notification/success/error sound effects
├── notifications/       # NEW — notification-specific icons (distinct from general icons/)
├── pdf/                  # NEW — PDF template assets (logo watermark, letterhead for invoices/
│                         receipts — cross-references `document_templates`, Part 3)
└── marketing/            # NEW — promo banner / social share graphic assets
```

## 3. Structure & Conventions

Naming (enforced going forward, `snake_case`, domain-prefixed):

| Prefix | Folder | Example |
|---|---|---|
| `ic_<name>.svg` | `icons/`, `icons/premium/` | `ic_coiffure_femme.svg` (matches Part 5's category `icon` column format exactly — verified consistent, no follow-up rename needed) |
| `il_<name>.png` | `illustrations/` | `il_empty_bookings.png` |
| `lt_<name>.json` | `lottie/` | `lt_success_check.json` |
| `cat_<slug>.png` | `categories/` | `cat_coiffure-femme.png` — **must match `categories.slug` from Part 5 exactly**, including hyphens (not underscores, unlike the `ic_` icon convention above — the two prefixes intentionally use different separator conventions, matching `icon` vs `image_url` column semantics) |
| `empty_<context>.svg` | `empty_states/` | `empty_bookings.svg`, `empty_search_results.svg` |
| `sound_<event>.mp3` | `sounds/` | `sound_payment_success.mp3` |

Every asset must be registered under its declared folder in `pubspec.yaml` — no loose top-level
files under `assets/`.

## 4. Contraintes & Edge Cases

- Folders are currently empty (`.gitkeep` only) — this migration is structural scaffolding, not
  an asset delivery. Populating them with real icons/illustrations/sounds is a separate,
  design-asset-production task outside this documentation pass's scope.
- `assets/categories/` naming is a hard dependency on Part 5's seeded `categories.slug` values —
  if a category is renamed (never done, only `name_fr`/`name_en` change per
  `docs/CATALOG_EXTENSION_GUIDE.md`), the image filename stays valid since slugs are immutable.

## 5. Sécurité

No user-uploaded content is ever bundled here — avatars/salon photos/review media all live in
Supabase Storage (`docs/DATABASE_ARCHITECTURE.md`), which has its own RLS-backed access control.
This folder is exclusively for assets shipped inside the app binary.

## 6. Performance

Bundled assets ship inside the APK/IPA and load with zero network latency — appropriate for
small, static, frequently-reused graphics (icons, illustrations, sounds). Category images
(`categories/`, potentially 72+ files once populated) should be kept under ~50KB each
(WebP/optimized PNG) to avoid meaningfully inflating app size — cross-reference Part 13
(`docs/PERFORMANCE_TARGETS.md`) for the app-size budget once one is set.

## 7. Stratégie de tests

`flutter analyze`/`flutter test` don't validate asset presence; a `pubspec.yaml` asset-path
lint (declared path exists on disk) is recommended as a pre-commit check but not currently
implemented.

## 8. Documentation associée

- `docs/CATALOG_ARCHITECTURE.md` / `CATALOG_EXTENSION_GUIDE.md` — `categories/` naming contract.
- `docs/ANIMATIONS_GUIDE.md` (Part 9) — when to use `lottie/` vs `animations/` vs native Flutter animation.
- `docs/DESIGN_SYSTEM.md` (Part 10) — icon/illustration usage in components.

## 9. Critères d'acceptation

- [x] `pubspec.yaml` asset declarations match the folder structure exactly — every new folder
  listed, no dangling references (verified: 18 declared paths, 18 real directories).
- [x] Category image naming (`cat_<slug>.png`) matches `categories.slug` from Part 5 1:1.
- [x] No parallel/duplicate folder created where an existing one already serves the purpose
  (`logos/` explicitly not created, cross-referenced to `branding/` instead).

## 10. Livrables

- `docs/ASSETS_GUIDE.md` (this file)
- 13 new empty folders under `assets/` (each with a `.gitkeep`, matching the existing convention)
- `pubspec.yaml` — 13 new asset path declarations
