import 'package:flutter/material.dart';
import '../constants/app_typography.dart';

/// Maps [AppTypography] onto the Material 3 [TextTheme] slots so that
/// widgets relying on `Theme.of(context).textTheme.*` (AppBar, Card,
/// Dialog, etc.) automatically pick up the KYNZA type scale.
abstract final class KynzaTextTheme {
  static const TextTheme dark = TextTheme(
    displayLarge: AppTypography.displayLarge,
    displayMedium: AppTypography.displayMedium,
    displaySmall: AppTypography.headlineLarge,

    headlineLarge: AppTypography.headlineLarge,
    headlineMedium: AppTypography.headlineMedium,
    headlineSmall: AppTypography.headlineSmall,

    titleLarge: AppTypography.titleLarge,
    titleMedium: AppTypography.titleMedium,
    titleSmall: AppTypography.titleSmall,

    bodyLarge: AppTypography.bodyLarge,
    bodyMedium: AppTypography.bodyMedium,
    bodySmall: AppTypography.bodySmall,

    labelLarge: AppTypography.labelLarge,
    labelMedium: AppTypography.labelMedium,
    labelSmall: AppTypography.labelSmall,
  );
}
