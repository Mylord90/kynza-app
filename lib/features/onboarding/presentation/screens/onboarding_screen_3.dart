import 'package:flutter/material.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../domain/onboarding_flow.dart';
import '../../domain/onboarding_slide.dart';
import '../widgets/kynza_onboarding_progress.dart';
import '../widgets/onboarding_bottom_scrim.dart';
import '../widgets/onboarding_carousel_controller.dart';
import '../widgets/onboarding_crossfade_carousel.dart';
import '../widgets/sliding_get_started_button.dart';

/// Onboarding screen 3 — the final CTA screen. Shares screen 1/2's
/// full-bleed editorial carousel, scrim and responsive panel strategy, but
/// swaps [KynzaOnboardingNextButton] for [SlidingGetStartedButton]: this is
/// the conversion moment, not an intermediate "next", so [onNext] here also
/// carries the flow-completion side effect (see the router's wiring —
/// this screen owns marking onboarding done, not screen 2 anymore).
class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  late final _carouselController = OnboardingCarouselController(
    slideCount: OnboardingSlides.screen3.length,
  );

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width >= AppBreakpoints.tablet;
    final panelWidth = isLargeScreen ? OnboardingFlow.panelWidth : size.width;
    final cacheWidth = (panelWidth * MediaQuery.devicePixelRatioOf(context))
        .round();
    final l10n = context.l10n;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        OnboardingCrossfadeCarousel(
          slides: OnboardingSlides.screen3,
          controller: _carouselController,
          cacheWidth: cacheWidth,
        ),
        const OnboardingBottomScrim(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingScreen3Headline,
                  style: AppTypography.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.onboardingScreen3Subtitle,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Center(
                  child: KynzaOnboardingProgress(
                    itemCount: OnboardingFlow.totalScreens,
                    currentIndex: 2,
                    currentProgress: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SlidingGetStartedButton(
                  label: l10n.onboardingGetStarted,
                  onPressed: widget.onNext,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLargeScreen
          ? Center(
              child: SizedBox(
                width: panelWidth,
                child: AspectRatio(aspectRatio: 9 / 16, child: content),
              ),
            )
          : content,
    );
  }
}
