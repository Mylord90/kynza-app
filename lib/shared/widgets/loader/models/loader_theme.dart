import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Thème visuel du `KynzaLoader`. Toutes les couleurs viennent de
/// [AppColors] (R19) — ce type ne permet pas d'injecter une couleur hex
/// arbitraire depuis l'extérieur du composant.
@immutable
class KynzaLoaderTheme {
  const KynzaLoaderTheme({
    this.gradientColors = AppColors.loaderGradientColors,
    this.backgroundDim = const Color(0x00000000),
  });

  /// Dégradé radial appliqué à chaque particule (variante `orbit`) ou au
  /// cercle (variante `pulse`).
  final List<Color> gradientColors;

  /// Fond assombri — utilisé uniquement par [KynzaLoaderOverlay].
  final Color backgroundDim;

  /// Thème par défaut, utilisé partout dans KYNZA.
  static const KynzaLoaderTheme standard = KynzaLoaderTheme();

  /// Overlay plein écran avec fond assombri (noir KYNZA à 80%).
  static const KynzaLoaderTheme overlay = KynzaLoaderTheme(
    backgroundDim: Color(0xCC09090B),
  );

  /// Pour un loader posé sur un fond gold plein (ex. `KynzaButton` variante
  /// primary) — le dégradé gold standard y serait peu lisible, on bascule
  /// sur un dégradé sombre pour garder le contraste.
  static const KynzaLoaderTheme onGoldBackground = KynzaLoaderTheme(
    gradientColors: [
      AppColors.surface,
      AppColors.background,
      AppColors.background,
    ],
  );
}
