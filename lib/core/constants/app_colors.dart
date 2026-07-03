import 'package:flutter/material.dart';

abstract class AppColors {
  static const background = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const surfaceVariant = Color(0xFF27272A);
  static const border = Color(0xFF3F3F46);

  static const primary = Color(0xFFEAB308);
  static const primaryVariant = Color(0xFFCA8A04);
  static const primaryGlow = Color(0x1AEAB308);

  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  // Was 0xFF52525B — measured at 1.93:1 against surfaceVariant (hint text)
  // and 2.57:1 against background, both failing WCAG AA's 4.5:1 minimum
  // for normal text (Phase 8, Enterprise Hardening pass). Lightened to a
  // value that passes both of textMuted's actual usage contexts (4.58:1 /
  // 6.12:1) while staying visibly one step darker than textSecondary.
  static const textMuted = Color(0xFF8E8E96);

  static const success = Color(0xFF22C55E);
  static const successBg = Color(0x1F22C55E);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0x1FEF4444);
  static const warning = Color(0xFFF97316);
  static const warningBg = Color(0x1FF97316);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0x1F3B82F6);

  static const goldGradientColors = [Color(0xFFEAB308), Color(0xFFD97706)];
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: goldGradientColors,
    transform: GradientRotation(2.356),
  );

  /// Palette dédiée au dégradé radial du KynzaLoader — `primary` reste
  /// l'accent de marque, ces tons l'entourent pour le dégradé "Orbite Dorée".
  static const goldLight = Color(0xFFFFD54A);
  static const goldCore = Color(0xFFF5C542);
  static const amberDeep = Color(0xFFD98A00);
  static const loaderGradientColors = [goldLight, goldCore, primary, amberDeep];
}
