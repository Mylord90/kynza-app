# KYNZA — Guide du Système Typographique

## Polices officielles

- **UI** : Plus Jakarta Sans — bundlée localement (`assets/fonts/PlusJakartaSans/`), font variable (poids 200–800 + italique) déclarée dans `pubspec.yaml` sous `flutter.fonts`.
- **Mono** : JetBrains Mono — bundlée localement (`assets/fonts/JetBrainsMono/`), font variable, réservée aux montants BIF/FBu, codes et timestamps.

Les deux polices sont chargées depuis les assets de l'app, jamais depuis le réseau (cohérent avec R03 — offline-first). `google_fonts` reste une dépendance déclarée mais n'est plus utilisé dans le thème.

## Classe officielle

`lib/core/constants/app_typography.dart` — `AppTypography` est la seule source de vérité pour les styles de texte.

```dart
Text('Bonjour KYNZA', style: AppTypography.headlineLarge)
Text('45 000 FBu', style: AppTypography.amountLabel)
Text('Label', style: Theme.of(context).textTheme.titleMedium) // via KynzaTextTheme
```

### Échelle historique (inchangée — ~130 usages existants)

| Style | Taille | Graisse | Usage |
|---|---|---|---|
| `displayLarge` | 32px | W900 | Splash / très grands titres |
| `h1` | 24px | W700 | Titres d'écran |
| `h2` | 18px | W600 | Titres de cartes / AppBar |
| `h3` | 15px | W500 | Sous-titres, noms d'items |
| `body` | 14px | W400 | Corps de texte standard |
| `bodySmall` | 12px | W400 | Captions |
| `button` | 14px | W600 | CTA |
| `label` | 11px | W700 | Labels de section (uppercase, tracking large) |
| `amount` / `amountMd` / `amountSm` | 24/18/14px | W800/W700/W600 | Montants BIF |
| `mono` | 13px | W400 | Codes, IDs |

### Échelle étendue (nouveaux écrans)

| Style | Taille | Graisse |
|---|---|---|
| `displayMedium` | 28px | W700 |
| `headlineLarge` / `headlineMedium` / `headlineSmall` | 24/22/20px | W700/W600/W600 |
| `titleLarge` / `titleMedium` / `titleSmall` | 18/16/14px | W600/W500/W500 |
| `bodyLarge` / `bodyMedium` / `bodySmall` | 16/14/12px | W400 |
| `labelLarge` / `labelMedium` / `labelSmall` | 14/12/10px | W600/W500/W500 |
| `amountLarge` / `amountLabel` | 28/14px | W800/W500 |
| `monoBold` | 13px | W700 |

`bodyMedium` est un alias de `body` (même valeur) pour la compatibilité avec l'API Material 3.

## Montants (BIF/FBu)

- Toujours `AppTypography.amount*` ou `AppTypography.mono*` — jamais une autre police pour un chiffre financier.
- Séparateur de milliers : ` ` (espace fine insécable), déjà implémenté dans `CurrencyFormatter`/`CurrencyDisplayService`.
- `FontFeature.tabularFigures()` est appliqué sur tous les styles montant/mono pour aligner les chiffres en colonnes.
- `KynzaAmountWidget` (`lib/shared/widgets/kynza_amount_widget.dart`) utilise déjà `AppTypography.amount` par défaut — ne pas dupliquer cette logique ailleurs.

## Intégration Material 3

`lib/core/theme/text_theme.dart` définit `KynzaTextTheme.dark`, qui mappe l'échelle étendue sur les 15 emplacements `TextTheme` de Material 3. `AppTheme.dark` (`lib/core/theme/app_theme.dart`) l'assigne à `ThemeData.textTheme`, donc tout widget Material (AppBar, Card, Dialog…) sans style explicite hérite automatiquement de la police et de la hiérarchie KYNZA.

## Convention couleur

Les couleurs par défaut des styles sont posées pour l'usage le plus courant (texte primaire/secondaire, or pour les montants). Pour une couleur différente, toujours passer par `.copyWith(color: AppColors.xxx)` — jamais de `Color(0x...)` en dur dans un `TextStyle`.

```dart
// Correct
Text('45 000 FBu', style: AppTypography.amountLarge.copyWith(color: AppColors.gold))

// Interdit
Text('Prix', style: TextStyle(color: Color(0xFFEAB308)))
```

## Interdictions

- Aucun `TextStyle(fontFamily: '...')` en dur hors de `AppTypography` — toujours `AppTypography.fontUI` / `AppTypography.fontMono`.
- Aucune valeur magique de `fontSize` hors de la scale ci-dessus.
- Aucune police autre que Plus Jakarta Sans (UI) et JetBrains Mono (montants/codes).

## Tests

`test/core/constants/app_typography_test.dart` vérifie :
- que tous les styles UI utilisent `fontUI`, tous les styles montant/mono utilisent `fontMono` ;
- que `FontFeature.tabularFigures()` est présent sur tous les styles montant/mono ;
- la cohérence de la hiérarchie de tailles ;
- que `KynzaTextTheme.dark` et `AppTheme.dark` exposent bien ces styles via l'API Material 3.

Lancer : `flutter test test/core/constants/app_typography_test.dart`.