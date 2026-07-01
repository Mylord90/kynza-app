# KYNZA — Rapport Implémentation Typographie

## Contexte

Audit du système typographique existant (`AppTypography`, `AppTheme`, `KynzaThemeExtension`) et extension vers l'échelle complète Dark Luxury, sans casser les ~130 usages existants.

## Bug corrigé (root cause)

`AppTypography` référençait déjà les familles `'PlusJakartaSans'` / `'JetBrainsMono'` (sans espace) dans ses `const TextStyle`, mais **aucun asset n'était bundlé sous ce nom** (`assets/fonts/` ne contenait qu'un `.gitkeep`). Ces styles retombaient donc silencieusement sur la police système, sur les ~130 fichiers qui les utilisent.

En parallèle, `AppTheme.dark` construisait le `TextTheme` ambiant via `GoogleFonts.plusJakartaSansTextTheme(...)`, qui charge la police réseau sous le nom `'Plus Jakarta Sans'` (avec espace) — un mécanisme différent et incohérent avec les styles explicites, en plus de violer le principe offline-first (R03).

## Fichiers créés

- `assets/fonts/PlusJakartaSans/PlusJakartaSans[wght].ttf` + `-Italic[wght].ttf` (police variable OFL, Google Fonts)
- `assets/fonts/JetBrainsMono/JetBrainsMono[wght].ttf` (police variable OFL, Google Fonts)
- `lib/core/theme/text_theme.dart` — `KynzaTextTheme.dark`, mapping Material 3
- `test/core/constants/app_typography_test.dart` — 9 tests
- `docs/TYPOGRAPHY_GUIDE.md`
- `docs/PHASE_TYPOGRAPHY_SUMMARY.md` (ce fichier)

## Fichiers modifiés

- `pubspec.yaml` — déclaration `flutter.fonts` pour les deux familles
- `lib/core/constants/app_typography.dart` — échelle historique conservée à l'identique ; ajout de l'échelle étendue (`displayMedium`, `headlineLarge/Medium/Small`, `titleLarge/Medium/Small`, `bodyLarge/Medium`, `labelLarge/Medium/Small`, `amountLarge`, `amountLabel`, `monoBold`) + constantes publiques `fontUI`/`fontMono` + `tabularFigures` sur tous les styles montant/mono existants
- `lib/core/theme/app_theme.dart` — `textTheme` alimenté par `KynzaTextTheme.dark` au lieu de `GoogleFonts.plusJakartaSansTextTheme`
- `lib/core/theme/kynza_theme_extension.dart` — `monoTextStyle` utilise la police bundlée au lieu de `GoogleFonts.jetBrainsMono()`
- `lib/features/dashboard/presentation/widgets/kynza_bar_chart_fl.dart` / `kynza_line_chart.dart` — `fontFamily: 'JetBrainsMono'` → `AppTypography.fontMono`
- `lib/shared/navigation/kynza_bottom_nav.dart` — `fontFamily: 'PlusJakartaSans'` → `AppTypography.fontUI`
- `lib/features/data_platform/templates/presentation/screens/template_editor_screen.dart` — `fontFamily: 'monospace'` (police système interdite) → `AppTypography.fontMono`

## Choix documentés

- **Assets locaux plutôt que `GoogleFonts` réseau** : cohérent avec R03 (offline-first), évite le FOUT, taille APK maîtrisée (2 fichiers de police variable au lieu d'un jeu de fichiers statiques par poids).
- **Polices variables** (`[wght].ttf`) plutôt que fichiers statiques par graisse : une seule paire de fichiers couvre tout l'axe de poids 200–800 (+ italique UI), supporté nativement par Flutter en déclarant plusieurs entrées `weight:` sur le même asset. Réduit l'empreinte APK par rapport à 9 fichiers statiques.
- **Échelle historique non modifiée** : `h1`, `h2`, `h3`, `body`, `button`, `label`, `amount`, `amountMd`, `amountSm`, `mono`, `displayLarge` gardent exactement leurs valeurs (taille, graisse, letterSpacing, couleur) déjà en production sur ~130 fichiers — seule leur police de rendu est désormais correcte. L'échelle demandée par la spec (24/20/16/14/12px) est ajoutée en parallèle sous de nouveaux noms plutôt que de réécrire les noms existants, pour zéro régression visuelle silencieuse.

## Tests

- `flutter analyze` → 0 issue
- `flutter test` → 241 tests passent (232 baseline + 9 nouveaux dans `app_typography_test.dart`)
- `dart format` → appliqué sur tous les fichiers modifiés

## Non fait (hors scope de cette passe)

- Golden test visuel de l'échelle typographique : non ajouté — nécessite une revue humaine du PNG de référence avant de le committer comme baseline (cf. convention documentée dans `test/golden/kynza_loader_golden_test.dart`).
- Migration des ~37 `TextStyle(...)` bruts restants dans l'app : audité, la grande majorité ne fixe qu'une `color` (héritage de la police ambiante déjà correcte via `KynzaTextTheme` désormais) ou stylise un émoji (`fontSize` seul, pas de police concernée) — aucune action requise. Les 4 vrais hardcodes de police (`fontFamily: ...`) ont été corrigés.