import 'package:flutter/widgets.dart';

/// Un onglet de la [KynzaBottomNav].
@immutable
class KynzaNavItem {
  const KynzaNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.semanticLabel,
    this.badgeCount = 0,
  });

  /// Icône affichée quand l'onglet est inactif.
  final IconData icon;

  /// Icône affichée quand l'onglet est actif. Si `null`, réutilise [icon]
  /// (seule la couleur change).
  final IconData? activeIcon;

  final String label;

  /// Libellé pour lecteurs d'écran (TalkBack/VoiceOver). Si `null`, [label]
  /// est utilisé.
  final String? semanticLabel;

  /// Nombre affiché en badge sur l'icône. `0` masque le badge.
  final int badgeCount;
}
