import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';

/// Segmented pagination indicator for the onboarding flow — one bar per
/// onboarding screen, the active segment fills gold over [currentProgress]
/// (0..1). Stateless and driver-fed so callers that do animate it (e.g. a
/// future in-screen transition) can scope re-paints to an `AnimatedBuilder`
/// instead of rebuilding the whole screen; most callers pass a constant
/// [currentProgress] of 1.0 since it marks the current screen, not a
/// per-frame value.
///
/// Reused across every onboarding screen — keep this widget generic
/// (no screen-specific logic) when extending the flow.
class KynzaOnboardingProgress extends StatelessWidget {
  const KynzaOnboardingProgress({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.currentProgress,
    this.segmentWidth = 22,
    this.segmentHeight = 3,
  });

  final int itemCount;
  final int currentIndex;
  final double currentProgress;
  final double segmentWidth;
  final double segmentHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.onboardingProgressStep(currentIndex + 1, itemCount),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(itemCount, (index) {
          final isPast = index < currentIndex;
          final isCurrent = index == currentIndex;
          final fill = isPast ? 1.0 : (isCurrent ? currentProgress : 0.0);
          return Padding(
            padding: EdgeInsets.only(
              right: index == itemCount - 1 ? 0 : AppSpacing.xs,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.pill_,
              child: SizedBox(
                width: segmentWidth,
                height: segmentHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0x40FFFFFF)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill.clamp(0.0, 1.0),
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
