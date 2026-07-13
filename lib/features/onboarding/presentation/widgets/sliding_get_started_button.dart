import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// The final onboarding CTA — a full-width gold capsule with a black circle
/// that slides left then bounces back on tap, distinct from
/// [KynzaOnboardingNextButton]'s circular blob used on screens 1-2 (this is
/// the conversion moment, not an intermediate "next").
///
/// [onPressed] only fires once the slide/bounce animation completes (or
/// immediately, under Reduce Motion) so the caller's navigation never races
/// the gesture the user just watched.
class SlidingGetStartedButton extends StatefulWidget {
  const SlidingGetStartedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  State<SlidingGetStartedButton> createState() =>
      _SlidingGetStartedButtonState();
}

class _SlidingGetStartedButtonState extends State<SlidingGetStartedButton>
    with SingleTickerProviderStateMixin {
  // Capsule height sits in the 56-60px premium-CTA range called out in the
  // design spec — not a spacing-scale multiple, so named here rather than
  // inlined.
  static const _height = 58.0;
  static const _circleMargin = AppSpacing.xs;
  static const _circleSize = _height - _circleMargin * 2;
  static const _slideDistance = AppSpacing.md;

  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spring,
  );

  late final _circleOffset = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: -_slideDistance).chain(
        CurveTween(curve: AppCurves.decelerate),
      ),
      weight: 55,
    ),
    TweenSequenceItem(
      tween: Tween(begin: -_slideDistance, end: 0.0).chain(
        CurveTween(curve: AppCurves.spring),
      ),
      weight: 45,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    KynzaHaptics.medium();
    if (MediaQuery.of(context).disableAnimations) {
      widget.onPressed();
      return;
    }
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.pill_,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(widget.label, style: AppTypography.button),
                Positioned(
                  right: _circleMargin,
                  child: AnimatedBuilder(
                    animation: _circleOffset,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_circleOffset.value, 0),
                      child: child,
                    ),
                    child: Container(
                      width: _circleSize,
                      height: _circleSize,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsBold.arrowRight,
                        color: AppColors.textPrimary,
                        size: _circleSize * 0.5,
                      ),
                    ),
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
