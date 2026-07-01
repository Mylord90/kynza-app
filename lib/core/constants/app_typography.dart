import 'package:flutter/material.dart';
import 'app_colors.dart';

/// KYNZA official typography scale.
///
/// Fonts are bundled locally as variable TrueType fonts (see
/// `pubspec.yaml` -> `flutter.fonts`), so every weight below resolves
/// through the same asset — no network fetch, no FOUT, consistent with
/// the app's offline-first rule.
///
/// - UI text always uses [fontUI] (Plus Jakarta Sans).
/// - Monetary amounts, codes and timestamps always use [fontMono]
///   (JetBrains Mono), with tabular figures so digits align in columns.
///
/// The original style names (`h1`, `h2`, `h3`, `body`, `button`, `label`,
/// `amount`, `amountMd`, `amountSm`) are kept unchanged below — they are
/// already used across ~130 files. The additional named styles
/// (`headlineLarge`, `titleMedium`, `amountLarge`, etc.) extend the scale
/// for new screens without altering existing visuals.
abstract class AppTypography {
  static const fontUI = 'PlusJakartaSans';
  static const fontMono = 'JetBrainsMono';

  static const _ui = fontUI;
  static const _mono = fontMono;

  // ── Original scale (unchanged — do not alter existing values) ─────────
  static const displayLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontFamily: _ui,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: AppColors.textSecondary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
  );
  static const label = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );
  static const amount = TextStyle(
    fontFamily: _mono,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const amountMd = TextStyle(
    fontFamily: _mono,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const amountSm = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const mono = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Extended scale (additive — for new screens) ────────────────────────
  static const displayMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const headlineLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _ui,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const titleLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const titleSmall = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.6,
    color: AppColors.textSecondary,
  );
  static const bodyMedium = body;

  static const labelLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.4,
    color: AppColors.background,
  );
  static const labelMedium = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const labelSmall = TextStyle(
    fontFamily: _ui,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// KPIs, dashboard hero amounts — larger than [amount].
  static const amountLarge = TextStyle(
    fontFamily: _mono,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Compact "45 000 FBu" label inside list rows.
  static const amountLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const monoBold = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
