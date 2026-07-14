import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// Secondary "already have an account?" link shown under
/// [SlidingGetStartedButton] on the final onboarding screen. Deliberately
/// low-key (no capsule, no shadow, no border) so it never competes with the
/// primary CTA — text-only, opacity-based feedback instead of the CTA's
/// haptic-heavy slide/bounce.
class OnboardingSignInLink extends StatefulWidget {
  const OnboardingSignInLink({
    super.key,
    required this.question,
    required this.accent,
    required this.onPressed,
    this.semanticHint,
  });

  final String question;
  final String accent;
  final VoidCallback onPressed;
  final String? semanticHint;

  @override
  State<OnboardingSignInLink> createState() => _OnboardingSignInLinkState();
}

class _OnboardingSignInLinkState extends State<OnboardingSignInLink>
    with SingleTickerProviderStateMixin {
  // "opacité 65-70%" in the design spec — a named constant (not a spacing
  // token) since it's a one-off translucency value, not a layout unit.
  static const _questionOpacity = 0.68;
  static const _tapFlashOpacity = 0.4;
  static const _minTapTarget = 48.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
  );
  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: _tapFlashOpacity), weight: 1),
    TweenSequenceItem(tween: Tween(begin: _tapFlashOpacity, end: 1.0), weight: 1),
  ]).animate(_controller);

  bool _hovering = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    KynzaHaptics.light();
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
    final decoration = _hovering ? TextDecoration.underline : TextDecoration.none;
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: widget.question,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary.withValues(alpha: _questionOpacity),
              decoration: decoration,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: widget.accent,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: decoration,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${widget.question} ${widget.accent}',
      hint: widget.semanticHint,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: _handleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTapTarget),
            child: Center(
              child: AnimatedBuilder(
                animation: _opacity,
                builder: (context, child) =>
                    Opacity(opacity: _opacity.value, child: child),
                child: text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
