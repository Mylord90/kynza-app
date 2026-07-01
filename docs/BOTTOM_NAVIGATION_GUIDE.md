# KYNZA Bottom Navigation — Guide du Composant Officiel

## Philosophie — "Lame Dorée"

Une bar flottante fine (`AppColors.surface` à 96% d'opacité, coins 28px,
micro-bordure `AppColors.surfaceVariant`), séparée du fond par des marges
(20px horizontal, 16px + safe area en bas) et une ombre portée légère.
L'onglet actif se translate de 8px vers le haut avec un halo doré subtil
(`AppColors.primaryGlow`) derrière l'icône, une pastille de 4px sous le
libellé, et une couleur gold (`AppColors.primary`) sur l'icône/le texte.
Aucun `BackdropFilter` (interdit dans KYNZA) — la translucidité vient
uniquement de `Color.withValues(alpha: ...)`.

Ce n'est pas une reproduction de l'image de référence qui a inspiré la
mission (couleurs, typographie et composition sont propres à KYNZA) — seule
la philosophie (bar flottante, onglet actif élevé, contraste surface/fond) a
été retenue.

## Portée actuelle — visuel uniquement

**Important** : cette phase remplace uniquement le *rendu* de la bottom nav.
Chaque `Home*Screen` (owner/manager/staff/client) garde son état local
`_tabIndex` et son `switch` pour choisir le corps affiché — **il n'existe
toujours pas de `ShellRoute`/`StatefulShellRoute` GoRouter**. Les onglets ne
sont donc pas des routes, pas deep-linkables individuellement, et l'état de
scroll n'est pas préservé automatiquement d'un onglet à l'autre.

Cette dette est trackée dans `AGENT.md` (SECTION 18) et la mémoire
`shellrouter_refactor_backlog` : la migration vers `StatefulShellRoute`
nécessite d'extraire chaque onglet actuel (ex. `_CalendarTab`,
`AdvancedDashboardTabs`, `_ProfileTab` côté owner) en écran routé à part
entière, puis de câbler les branches — un chantier séparé, plus large,
touchant les 4 rôles et les guards de route.

## Architecture

```
lib/shared/navigation/
├── kynza_bottom_nav.dart   — widget (StatefulWidget, un AnimationController par onglet)
├── kynza_nav_item.dart     — KynzaNavItem (icon, activeIcon, label, semanticLabel, badgeCount)
└── kynza_nav_theme.dart    — KynzaNavTheme (tokens visuels, valeurs par défaut = AppColors)
```

Pas de sous-dossiers `models/`/`widgets/`/`providers/` séparés : la portée
actuelle (pas de Freezed, pas de provider de badges global, pas de shell) ne
justifie pas la subdivision prévue par le brief initial.

## Utilisation

Chaque `Home*Screen` construit sa propre liste de `KynzaNavItem` (les
libellés dépendent de `context.l10n`, donc pas de config statique
pré-construite) et la passe à `KynzaBottomNav` à la place de
`BottomNavigationBar` :

```dart
bottomNavigationBar: KynzaBottomNav(
  currentIndex: _tabIndex,
  onItemTapped: (index) => setState(() => _tabIndex = index),
  items: [
    KynzaNavItem(
      icon: PhosphorIconsRegular.calendarCheck,
      activeIcon: PhosphorIconsBold.calendarCheck,
      label: context.l10n.navCalendar,
    ),
    // ...
  ],
),
```

Icônes : **Phosphor Icons** (`phosphor_flutter`), variantes `Regular`
(inactif) / `Bold` (actif). Ne jamais utiliser `Icons.*` (Material) pour un
nouvel onglet.

## Badges

`KynzaNavItem.badgeCount` (défaut `0`) affiche un badge rouge sur l'icône
quand `> 0` (plafonné à `99+`). Aucun provider global de badges n'existe
pour l'instant — c'est à l'écran appelant de calculer le compte (ex. via un
`ref.watch` existant) et de le passer directement. Ne pas introduire un
`NavBadgeNotifier` global tant qu'aucun écran n'a réellement besoin de
badges partagés entre plusieurs points d'entrée.

## Accessibilité

- Respecte `MediaQuery.disableAnimations` : translation et halo désactivés,
  mais la pastille et le changement de couleur restent (communication de
  l'état non-animée).
- `Semantics(selected: isActive, button: true)` sur chaque onglet pour
  TalkBack/VoiceOver.
- Libellés `maxLines: 1` + `ellipsis` pour rester stables aux grandes
  tailles de police.

## Tests

`test/shared/navigation/kynza_bottom_nav_test.dart` — rendu des libellés,
callback de tap, `Semantics.isSelected`, badge (affichage + plafond `99+`),
`disableAnimations`, dispose propre des `AnimationController`.