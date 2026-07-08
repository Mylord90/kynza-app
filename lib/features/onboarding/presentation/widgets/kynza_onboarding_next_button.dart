import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/utils/haptics.dart';

/// Organic wave-shaped "next" button — black blob, gold circle, black
/// chevron. Anchor this in the bottom-right corner of the screen via
/// `Positioned` at the call site; the widget itself only owns its shape,
/// tap animation and semantics so it stays reusable across every onboarding
/// screen (see KynzaOnboardingProgress for the same convention).
class KynzaOnboardingNextButton extends StatefulWidget {
  const KynzaOnboardingNextButton({
    super.key,
    required this.onPressed,
    this.size = 88,
    this.semanticLabel,
  });

  final VoidCallback onPressed;
  final double size;
  final String? semanticLabel;

  @override
  State<KynzaOnboardingNextButton> createState() =>
      _KynzaOnboardingNextButtonState();
}

class _KynzaOnboardingNextButtonState extends State<KynzaOnboardingNextButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.92,
  ).animate(CurvedAnimation(parent: _pressController, curve: AppCurves.standard));

  late final AnimationController _rippleController = AnimationController(
    vsync: this,
    duration: AppDurations.rich,
  );
  late final Animation<double> _ripple = CurvedAnimation(
    parent: _rippleController,
    curve: AppCurves.decelerate,
  );

  @override
  void dispose() {
    _pressController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _pressController.forward();

  void _handleTapUp(TapUpDetails details) => _pressController.reverse();

  void _handleTapCancel() => _pressController.reverse();

  void _handleTap() {
    KynzaHaptics.light();
    _rippleController.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? context.l10n.commonNext,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(widget.size),
                  painter: _BlobPainter(
                    color: AppColors.background,
                    borderColor: AppColors.border,
                  ),
                ),
                ClipPath(
                  clipper: _BlobClipper(),
                  child: AnimatedBuilder(
                    animation: _ripple,
                    builder: (context, _) => CustomPaint(
                      size: Size.square(widget.size),
                      painter: _RipplePainter(progress: _ripple.value),
                    ),
                  ),
                ),
                Container(
                  width: widget.size * 0.44,
                  height: widget.size * 0.44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: Icon(
                    PhosphorIconsBold.arrowRight,
                    color: AppColors.background,
                    size: widget.size * 0.22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Organic wave silhouette shared by the fill painter and the ripple clip.
Path _blobPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * 0.38, 0)
    ..cubicTo(w * 0.75, -h * 0.02, w * 1.02, h * 0.22, w, h * 0.55)
    ..cubicTo(w * 0.99, h * 0.85, w * 0.85, h * 1.02, w * 0.55, h)
    ..cubicTo(w * 0.22, h * 1.01, -w * 0.02, h * 0.7, 0, h * 0.38)
    ..cubicTo(-w * 0.01, h * 0.12, w * 0.12, -h * 0.01, w * 0.38, 0)
    ..close();
}

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _blobPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Fills the blob and outlines it with a hairline border — the blob is the
/// same deep black as the app background/scrim it sits on, so without a
/// border its organic silhouette wouldn't read against them at all.
class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _blobPath(size);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// Soft radial pulse on tap, clipped to the blob — replaces the default
/// Material splash with a discreet KYNZA-gold ripple.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.9 * progress;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: (1 - progress) * 0.35);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
