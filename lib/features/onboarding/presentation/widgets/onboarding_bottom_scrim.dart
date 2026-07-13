import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The dark bottom scrim over every onboarding photo — a plain
/// [LinearGradient] (never `BackdropFilter`/blur) guaranteeing the
/// headline/subtitle stay legible over any photo. Identical on every
/// onboarding screen; shared so the overlay can never drift between them.
class OnboardingBottomScrim extends StatelessWidget {
  const OnboardingBottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              AppColors.background.withValues(alpha: 0.85),
              AppColors.background,
            ],
            stops: const [0.0, 0.55, 0.85, 1.0],
          ),
        ),
      ),
    );
  }
}
