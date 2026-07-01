# KYNZA Loader — Guide du Composant Officiel

## Philosophie

**"Orbite Dorée"** — des particules de tailles et opacités variables tournent
autour d'un centre invisible, avec un léger décalage angulaire organique
(±3-5°, fixe par particule) qui casse la régularité mécanique d'un cercle
parfait. La particule la plus proche de la position "en tête" grossit et
s'éclaircit légèrement (effet de comète subtil), créant une pulsation qui
traverse l'orbite au fil de la rotation.

Ce n'est **pas** une copie du loader de référence qui a inspiré la mission —
seule la philosophie (particules vivantes en orbite) a été retenue. La
palette, le rythme (1400ms/cycle), le nombre de particules par taille et le
décalage organique sont propres à KYNZA et à son Design System Dark Luxury.

## Architecture

```
lib/shared/widgets/loader/
├── kynza_loader.dart                 — widget racine (StatefulWidget)
├── kynza_loader_painter.dart         — CustomPainter (orbit + pulse)
├── kynza_loader_controller.dart      — wrapper AnimationController
├── models/
│   ├── loader_size.dart              — enum KynzaLoaderSize
│   ├── loader_theme.dart             — KynzaLoaderTheme (standard/overlay/onGoldBackground)
│   └── loader_variant.dart           — enum KynzaLoaderVariant
├── widgets/
│   ├── loader_inline.dart            — KynzaLoaderInline
│   ├── loader_fullscreen.dart        — KynzaLoaderFullscreen
│   ├── loader_overlay.dart           — KynzaLoaderOverlay
│   └── loader_button.dart            — KynzaLoaderButton
└── providers/
    └── loader_overlay_provider.dart  — loaderOverlayProvider (Riverpod, Notifier<bool>)
```

Tout est exporté via `lib/shared/widgets/kynza_widgets.dart`.

## Composants disponibles

- **`KynzaLoader`** — le composant de base. `size`, `theme`, `variant`,
  `semanticLabel` optionnels.
- **`KynzaLoaderInline`** — dans le flux d'un widget (listes, cards,
  gardes de route). Centré, padding vertical `AppSpacing.xl`, message
  optionnel sous le loader.
- **`KynzaLoaderFullscreen`** — écran de chargement dédié. `Scaffold` fond
  `AppColors.background`, loader `fullscreen` centré.
- **`KynzaLoaderOverlay`** (+ `loaderOverlayProvider`) — overlay bloquant,
  `PopScope(canPop: false)`, fond assombri 80%. Utilisable directement comme
  corps d'écran (OAuth, vérification d'invitation/parrainage) ou globalement
  via le provider Riverpod (déjà câblé dans `main.dart` au-dessus de
  `MaterialApp.router`) :
  ```dart
  ref.read(loaderOverlayProvider.notifier).show();
  // ... opération async critique (export, paiement) ...
  ref.read(loaderOverlayProvider.notifier).hide();
  ```
- **`KynzaLoaderButton`** — remplace l'état `isLoading` d'un bouton.
  `onGoldBackground: true` quand le bouton a un fond gold plein (bascule sur
  `KynzaLoaderTheme.onGoldBackground`, un dégradé sombre lisible sur gold).

## Tailles (`KynzaLoaderSize`)

| Taille | Diamètre | Particules | Usage |
|---|---|---|---|
| `small` | 16px | 5 | `KynzaLoaderButton`, badges de sync |
| `medium` | 28px | 6 | Listes, cards, upload inline, variante `pulse` du radar de paiement |
| `large` | 48px | 7 | Section complète (détail salon, gardes de route, chargement plein corps) |
| `fullscreen` | 64px | 7 | `KynzaLoaderFullscreen`, `KynzaLoaderOverlay` |

## Variantes (`KynzaLoaderVariant`)

- **`orbit`** (défaut) — particules en orbite, tous les contextes standards.
- **`pulse`** — un seul cercle qui respire. Réservé aux très petits espaces
  ou aux compositions qui ont déjà leur propre rythme visuel (ex.
  `RadarPulseWidget` — les anneaux concentriques existants + un `pulse`
  central au lieu d'un `orbit`, pour ne pas superposer deux rythmes
  différents).
- **`linear`** (extension future, non codée) — progression déterministe.
  Aucun cas d'usage identifié dans le projet à ce jour (pas d'upload avec %
  connu, pas de barre de progression). À ajouter le jour où un tel besoin
  apparaît, sans toucher à `orbit`/`pulse`.

## Exception documentée : `RefreshIndicator`

Le geste natif de pull-to-refresh n'est pas réimplémentable avec un
`CustomPainter` sans recréer tout le comportement de scroll+glissement de
`RefreshIndicator` (hors scope). Décision : on garde le widget Material natif
mais on le style aux couleurs KYNZA sur les 12 écrans qui l'utilisent :

```dart
RefreshIndicator(
  color: AppColors.primary,
  backgroundColor: AppColors.surface,
  onRefresh: () async { ... },
  child: ...,
)
```

C'est la **seule** dérogation acceptée à la règle "zéro
`CircularProgressIndicator` brut".

## Accessibilité

- **Reduce Motion** (`MediaQuery.disableAnimations`) — la pulsation
  taille/opacité est désactivée (facteurs figés), mais la rotation continue
  de tourner : un loader totalement statique ne communique plus l'état "en
  cours" (Apple HIG / Material 3).
- **Screen Reader** — `Semantics(label: ..., liveRegion: true)` sur
  `KynzaLoader`. Label par défaut : `context.l10n.commonLoading`
  ("Chargement…"), overridable via `semanticLabel`.
- **High Contrast** (`MediaQuery.highContrast`) — dégradé multi-stop
  remplacé par une couleur pleine `AppColors.primary`, opacité minimale
  relevée à 0.7 (au lieu de 0.4).

## Performance

- `RepaintBoundary` autour du `CustomPaint` — isole le repaint du reste de
  l'arbre.
- `SingleTickerProviderStateMixin` (un seul `AnimationController` par
  loader).
- `shouldRepaint` compare uniquement les valeurs qui affectent le rendu
  (`progress`, `size`, `variant`, `reduceMotion`, `highContrast`, `theme`).
- Un seul `Paint()` réutilisé pour toutes les particules d'un même frame
  (variante `orbit`) — seul le `shader` (qui dépend du centre de chaque
  particule) est recréé par itération.
- `dispose()` systématique de l'`AnimationController` — vérifié par
  `test/shared/widgets/loader/kynza_loader_test.dart`.
- `test/shared/widgets/loader/kynza_loader_performance_test.dart` simule un
  cycle prolongé (5s à ~60fps) et 12 loaders simultanés dans une liste :
  aucune exception, aucun leak détecté.

## Migration depuis `CircularProgressIndicator` / `KynzaSpinner`

Le projet avait déjà centralisé ses spinners dans `KynzaSpinner`
(remplacé, supprimé) — voir `docs/audit/LOADER_AUDIT.md` pour le détail
fichier par fichier.

| Ancien pattern | Nouveau |
|---|---|
| `Center(child: KynzaSpinner())` (chargement de section/écran) | `KynzaLoaderInline(size: large)` |
| `KynzaSpinner(size: 20, color: textColor)` (dans un bouton) | `KynzaLoaderButton(onGoldBackground: ...)` |
| `KynzaLoadingOverlay(...)` | `KynzaLoaderOverlay(...)` |
| `CircularProgressIndicator` brut dans un `Container`/tile | `KynzaLoader(size: ...)` directement (sans wrapper `Inline` si le conteneur a déjà son propre centrage/padding) |

## Comment NE PAS utiliser ce composant

- Ne jamais instancier `CircularProgressIndicator` directement — le seul
  répertoire autorisé pour un `ProgressIndicator` Material est
  `RefreshIndicator` (Phase 5.5 ci-dessus).
- Ne jamais passer une couleur hex hors `AppColors` à `KynzaLoaderTheme`
  (R19) — utiliser un des thèmes prédéfinis (`standard`, `overlay`,
  `onGoldBackground`) ou ajouter un token à `AppColors` si un vrai nouveau
  besoin apparaît.
- Ne jamais utiliser `KynzaLoader` pour remplacer un `KynzaSkeleton` — ce
  sont deux systèmes différents et complémentaires. Le skeleton est un
  placeholder *pour* le contenu (forme de la donnée à venir) ; le loader
  signale une opération active sans préjuger de la forme du résultat.
