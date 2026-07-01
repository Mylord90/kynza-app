import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_curves.dart';
import 'models/loader_size.dart';
import 'models/loader_theme.dart';
import 'models/loader_variant.dart';

/// Décalage angulaire organique fixe par particule (déterministe, jamais
/// recalculé/aléatoire) — évite l'effet "mécanique parfait" d'un cercle
/// parfaitement régulier. Valeurs en radians, ±3-5°.
const List<double> _organicAngleOffsets = [
  0.02,
  -0.04,
  0.03,
  -0.02,
  0.05,
  -0.03,
  0.01,
];

/// Dessine les particules en orbite (ou le cercle pulsant) du `KynzaLoader`.
/// Repaint déclenché uniquement par `AnimatedBuilder` — aucun `setState` ni
/// logique métier ici.
class KynzaLoaderPainter extends CustomPainter {
  KynzaLoaderPainter({
    required this.progress,
    required this.size,
    required this.theme,
    required this.variant,
    required this.reduceMotion,
    required this.highContrast,
  });

  /// 0.0 → 1.0, un cycle de rotation complet.
  final double progress;
  final KynzaLoaderSize size;
  final KynzaLoaderTheme theme;
  final KynzaLoaderVariant variant;
  final bool reduceMotion;
  final bool highContrast;

  static const double _orbitRadiusRatio = 0.72;
  static const List<double> _gradientStops = [0.0, 0.35, 0.7, 1.0];

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = canvasSize.center(Offset.zero);

    if (variant == KynzaLoaderVariant.pulse) {
      _paintPulse(canvas, center, canvasSize);
      return;
    }

    final orbitRadius = canvasSize.width / 2 * _orbitRadiusRatio;
    _paintOrbit(canvas, center, orbitRadius, canvasSize.width);
  }

  void _paintOrbit(
    Canvas canvas,
    Offset center,
    double orbitRadius,
    double canvasWidth,
  ) {
    final particleCount = size.particleCount;
    final baseParticleRadius = canvasWidth * size.strokeRatio;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < particleCount; i++) {
      final baseAngle = (2 * math.pi / particleCount) * i;
      final organicOffset =
          _organicAngleOffsets[i % _organicAngleOffsets.length];
      final angle = baseAngle + organicOffset + (progress * 2 * math.pi);

      final particleCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      // Position de cette particule dans le cycle de rotation
      // (0.0 = à la position "en tête", la plus grande/lumineuse).
      final cycleLag = i / particleCount;
      final localProgress = (progress - cycleLag) % 1.0;
      final normalized = localProgress < 0
          ? localProgress + 1.0
          : localProgress;
      final proximityToLead = (1.0 - normalized).clamp(0.0, 1.0);
      final eased = AppCurves.standard.transform(proximityToLead);

      final scaleFactor = reduceMotion ? 1.0 : 0.65 + (0.45 * eased);
      final opacityFactor = highContrast
          ? (0.7 + 0.3 * eased)
          : reduceMotion
          ? 0.85
          : 0.4 + (0.6 * eased);
      final particleRadius = baseParticleRadius * scaleFactor;

      paint.shader = highContrast
          ? null
          : RadialGradient(
              colors: theme.gradientColors,
              stops: theme.gradientColors.length == _gradientStops.length
                  ? _gradientStops
                  : null,
            ).createShader(
              Rect.fromCircle(center: particleCenter, radius: particleRadius),
            );
      paint.color = highContrast
          ? AppColors.primary.withValues(alpha: opacityFactor)
          : Colors.white.withValues(alpha: opacityFactor);

      canvas.drawCircle(particleCenter, particleRadius, paint);
    }
  }

  void _paintPulse(Canvas canvas, Offset center, Size canvasSize) {
    final maxRadius = canvasSize.width / 2;
    final pulseProgress = reduceMotion
        ? 0.5
        : AppCurves.standard.transform(progress);
    final radius = maxRadius * (0.6 + 0.4 * pulseProgress);
    final opacity = highContrast
        ? 0.7
        : reduceMotion
        ? 0.9
        : (1.0 - pulseProgress) * 0.8 + 0.2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = highContrast
          ? null
          : RadialGradient(
              colors: theme.gradientColors,
            ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..color = highContrast
          ? AppColors.primary.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: opacity);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant KynzaLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.size != size ||
        oldDelegate.variant != variant ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.highContrast != highContrast ||
        oldDelegate.theme != theme;
  }
}
