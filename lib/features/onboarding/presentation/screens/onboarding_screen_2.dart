import 'package:flutter/material.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../domain/onboarding_flow.dart';
import '../../domain/onboarding_slide.dart';
import '../widgets/kynza_onboarding_next_button.dart';
import '../widgets/kynza_onboarding_progress.dart';
import '../widgets/onboarding_bottom_scrim.dart';
import '../widgets/onboarding_carousel_controller.dart';
import '../widgets/onboarding_crossfade_carousel.dart';

/// Onboarding screen 2 — sells KYNZA's benefits (trusted pros, instant
/// booking, premium experience, everything in one app) on the same
/// full-bleed editorial carousel, scrim, next button and responsive panel
/// strategy as [OnboardingScreen1], second of [OnboardingFlow.totalScreens].
class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  late final _carouselController = OnboardingCarouselController(
    slideCount: OnboardingSlides.screen2.length,
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

    final content = Stack(
      fit: StackFit.expand,
      children: [
        OnboardingCrossfadeCarousel(
          slides: OnboardingSlides.screen2,
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
                const _OnboardingScreen2Headline(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.onboardingScreen2Subtitle,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const KynzaOnboardingProgress(
                      itemCount: OnboardingFlow.totalScreens,
                      currentIndex: 1,
                      currentProgress: 1.0,
                    ),
                    KynzaOnboardingNextButton(onPressed: widget.onNext),
                  ],
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

class _OnboardingScreen2Headline extends StatelessWidget {
  const _OnboardingScreen2Headline();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text.rich(
      TextSpan(
        style: AppTypography.headlineLarge,
        children: [
          TextSpan(text: l10n.onboardingScreen2HeadlineLine1),
          const TextSpan(text: '\n'),
          TextSpan(
            text: l10n.onboardingScreen2HeadlineLine2,
            style: const TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
