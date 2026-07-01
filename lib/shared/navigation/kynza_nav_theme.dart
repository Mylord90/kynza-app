import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Tokens visuels de la [KynzaBottomNav] — concept "Lame Dorée".
@immutable
class KynzaNavTheme {
  const KynzaNavTheme({
    this.backgroundColor = AppColors.surface,
    this.backgroundOpacity = 0.96,
    this.borderColor = AppColors.surfaceVariant,
    this.borderWidth = 0.5,
    this.borderRadius = 28.0,
    this.iconColorActive = AppColors.primary,
    this.iconColorInactive = AppColors.textSecondary,
    this.labelColorActive = AppColors.primary,
    this.labelColorInactive = AppColors.textSecondary,
    this.iconSizeActive = 26.0,
    this.iconSizeInactive = 22.0,
    this.indicatorColor = AppColors.primary,
    this.haloColor = AppColors.primaryGlow,
    this.haloRadius = 24.0,
    this.horizontalMargin = 20.0,
    this.bottomMargin = 16.0,
    this.verticalPadding = 12.0,
    this.activeItemElevation = -8.0,
    this.shadowColor = const Color(0x40000000),
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeInOutCubic,
  });

  final Color backgroundColor;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color iconColorActive;
  final Color iconColorInactive;
  final Color labelColorActive;
  final Color labelColorInactive;
  final double iconSizeActive;
  final double iconSizeInactive;
  final Color indicatorColor;
  final Color haloColor;
  final double haloRadius;
  final double horizontalMargin;
  final double bottomMargin;
  final double verticalPadding;

  /// Translation Y (négative = vers le haut) de l'icône active.
  final double activeItemElevation;
  final Color shadowColor;
  final Duration animationDuration;
  final Curve animationCurve;

  static const KynzaNavTheme standard = KynzaNavTheme();
}
