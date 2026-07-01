# KYNZA — Rapport d'implémentation du Loader Officiel

## Résumé exécutif

Création de `KynzaLoader` ("Orbite Dorée"), le composant de chargement
officiel et unique de KYNZA — `CustomPainter` + `AnimationController` natifs,
aucune dépendance externe. L'audit préalable (`docs/audit/LOADER_AUDIT.md`)
a montré que le projet avait déjà centralisé ses spinners dans un widget
unique (`KynzaSpinner`), réduisant la mission à un remplacement ciblé plutôt
qu'à un balayage généralisé de l'application : 1 point de passage principal
(14 call sites) + 1 `CircularProgressIndicator` brut isolé + 12
`RefreshIndicator` non stylés.

Résultat : zéro `CircularProgressIndicator` brut restant dans `lib/` (hors
exception documentée `RefreshIndicator`), `flutter analyze` à 0 issue,
225/225 tests passants (191 en baseline + 34 nouveaux/pré-existants, dont 25
spécifiquement écrits pour le loader), goldens générés et inspectés
visuellement.

## Fichiers créés

```
lib/shared/widgets/loader/
├── kynza_loader.dart
├── kynza_loader_painter.dart
├── kynza_loader_controller.dart
├── models/
│   ├── loader_size.dart
│   ├── loader_theme.dart
│   └── loader_variant.dart
├── widgets/
│   ├── loader_inline.dart
│   ├── loader_fullscreen.dart
│   ├── loader_overlay.dart
│   └── loader_button.dart
└── providers/
    └── loader_overlay_provider.dart

test/shared/widgets/loader/
├── kynza_loader_painter_test.dart      (9 tests)
├── kynza_loader_test.dart              (8 tests)
└── kynza_loader_performance_test.dart  (2 tests)

test/golden/
├── kynza_loader_golden_test.dart       (6 tests)
└── goldens/
    ├── kynza_loader_orbit_small_p0.png
    ├── kynza_loader_orbit_medium_p50.png
    ├── kynza_loader_orbit_large_p25.png
    ├── kynza_loader_pulse_p0.png
    ├── kynza_loader_pulse_p50.png
    └── kynza_loader_button_small.png

docs/audit/LOADER_AUDIT.md
docs/LOADER_GUIDE.md
docs/PHASE_LOADER_SUMMARY.md (ce fichier)
```

## Fichiers supprimés

```
lib/shared/widgets/kynza_spinner.dart          (remplacé par KynzaLoader)
lib/shared/widgets/kynza_loading_overlay.dart  (remplacé par KynzaLoaderOverlay)
```

## Fichiers modifiés (hors reformatage global)

**Design system** — nouveaux tokens ajoutés (R19 : pas de hex hors `AppColors`) :
- `lib/core/constants/app_colors.dart` (`goldLight`, `goldCore`, `amberDeep`, `loaderGradientColors`)
- `lib/core/constants/app_durations.dart` (`loaderOrbit` = 1400ms)

**Intégration app** :
- `lib/main.dart` — `Stack` + `loaderOverlayProvider` au-dessus de `MaterialApp.router`
- `lib/shared/widgets/kynza_widgets.dart` — barrel export mis à jour

**Migration `KynzaSpinner` → `KynzaLoader*`** (14 call sites) :
- `lib/shared/widgets/kynza_button.dart` → `KynzaLoaderButton`
- `lib/features/auth/presentation/widgets/kynza_oauth_button.dart` → `KynzaLoaderButton`
- `lib/features/billing/presentation/screens/billing_screen.dart` → `KynzaLoaderInline`
- `lib/features/billing/presentation/screens/invoice_history_screen.dart` → `KynzaLoaderInline`
- `lib/features/billing/presentation/screens/subscription_plans_screen.dart` → `KynzaLoaderInline`
- `lib/features/permissions/presentation/screens/permission_group_detail_screen.dart` → `KynzaLoaderInline`
- `lib/features/loyalty/presentation/screens/loyalty_qr_screen.dart` → `KynzaLoader`
- `lib/features/reviews/presentation/screens/leave_review_screen.dart` (×2) → `KynzaLoaderInline`
- `lib/features/booking/presentation/screens/salon_detail_screen.dart` → `KynzaLoaderInline`
- `lib/features/salon/presentation/widgets/media_upload_button.dart` → `KynzaLoader`
- `lib/features/payment/presentation/widgets/radar_pulse_widget.dart` → `KynzaLoader` (variante `pulse`)
- `lib/core/router/app_router.dart` (23 occurrences) → `KynzaLoaderInline`

**Migration `KynzaLoadingOverlay` → `KynzaLoaderOverlay`** (4 call sites) :
- `lib/features/auth/presentation/screens/reset_password_screen.dart`
- `lib/core/router/auth_callback_screen.dart`
- `lib/features/staff/presentation/screens/accept_invitation_screen.dart`
- `lib/features/referral/presentation/screens/referral_claim_screen.dart`

**`CircularProgressIndicator` brut isolé** :
- `lib/features/evolution/version_manager/presentation/screens/force_update_screen.dart` → `KynzaLoaderButton(onGoldBackground: true)`

**`RefreshIndicator` stylé gold** (Phase 5.5, exception documentée, 12 fichiers) :
`commission_screen.dart`, `invoice_history_screen.dart`, `staff_list_screen.dart`,
`staff_detail_screen.dart`, `my_performance_screen.dart`, `audit_log_screen.dart`,
`advanced_dashboard_screen.dart`, `salon_reviews_tab.dart`,
`marketing_dashboard_screen.dart`, `notifications_screen.dart`,
`services_list_screen.dart`, `advanced_search_screen.dart`.

**Test existant mis à jour** :
- `test/widget_test.dart` — l'assertion `KynzaButton` vérifie désormais
  `find.byType(KynzaLoaderButton)` au lieu de `CircularProgressIndicator`.

## Nombre total d'occurrences remplacées

- 14 `KynzaSpinner` (dont 2 internes à des widgets déjà remplacés eux-mêmes)
- 4 `KynzaLoadingOverlay`
- 1 `CircularProgressIndicator` brut
- 12 `RefreshIndicator` stylés (non remplacés — exception documentée)

**Total : 31 sites de chargement traités.**

## Tests ajoutés (25)

- `kynza_loader_painter_test.dart` (9) — `shouldRepaint` (6 cas) + déterminisme
  du rendu orbit/pulse via rastérisation pixel-à-pixel (3 cas, exécutés dans
  `tester.runAsync()` — `picture.toImage()` est un aller-retour GPU réel qui
  ne se résout jamais dans la zone FakeAsync de `testWidgets` sans ça).
- `kynza_loader_test.dart` (8) — dispose de l'`AnimationController`, reduce
  motion, labels Semantics (par défaut + override), `KynzaLoaderInline`
  (message optionnel), `KynzaLoaderFullscreen` (couleur de fond + taille),
  `KynzaLoaderOverlay` (`PopScope(canPop:false)`), `KynzaLoaderButton` (taille).
- `kynza_loader_performance_test.dart` (2) — cycle d'animation prolongé
  (5s simulées à ~60fps, aucune exception) et 12 loaders simultanés dans une
  liste (viewport élargi à 2400px pour que `ListView.builder` matérialise
  bien les 12 items — sinon seuls les items visibles sont construits).
- `kynza_loader_golden_test.dart` (6) — orbit small/medium/large à 3
  progressions différentes, pulse à 2 progressions, `KynzaLoaderButton`.

## Bugs rencontrés et résolutions pendant l'écriture des tests

1. **Timeout de 10 min × 3** sur les tests de déterminisme : `picture.toImage()`
   appelé directement dans `testWidgets` sans `tester.runAsync()` ne se
   résout jamais (la zone `FakeAsync` de `testWidgets` ne sert pas les
   callbacks GPU réels). Corrigé en enveloppant chaque corps de test dans
   `await tester.runAsync(() async { ... })`.
2. **Semantics label introuvable** : le test ne fixait pas `locale:
   Locale('fr')` sur le `MaterialApp` de test, donc `context.l10n.commonLoading`
   résolvait dans la locale par défaut de l'environnement de test (pas 'fr')
   au lieu de "Chargement…". Corrigé en fixant la locale explicitement.
3. **`findsNWidgets(12)` → seulement 10 trouvés** : `ListView.builder` ne
   matérialise que les items dans le viewport (600px logiques par défaut en
   test) ; 12 `KynzaLoaderInline` à padding vertical ne tiennent pas tous à
   l'écran. Corrigé en agrandissant la taille de vue du test
   (`tester.view.physicalSize`) à 2400px de haut.

## Résultats

- `flutter analyze` : 0 issue (avant et après migration).
- `flutter test` : 225/225 passants (191 baseline + 34, dont 25 nouveaux
  tests loader écrits dans cette phase).
- `dart format --set-exit-if-changed lib/ test/` : propre après une passe
  qui a reformaté 89 fichiers pré-existants non formatés (hérités d'une
  phase précédente) — 2 infos `curly_braces_in_flow_control_structures`
  introduites par ce reformatage dans `advanced_dashboard_screen.dart` ont
  été corrigées pour revenir à 0 issue.
- Goldens générés (`--update-goldens`) puis inspectés visuellement une fois
  (voir capture des deux images de référence pendant la session) : l'orbite
  dorée montre bien l'effet de comète attendu, la variante pulse un cercle
  qui respire — conforme à la direction artistique "Orbite Dorée" sans
  copier le design de référence.

## Captures golden générées

`test/golden/goldens/` : `kynza_loader_orbit_small_p0.png`,
`kynza_loader_orbit_medium_p50.png`, `kynza_loader_orbit_large_p25.png`,
`kynza_loader_pulse_p0.png`, `kynza_loader_pulse_p50.png`,
`kynza_loader_button_small.png`.
