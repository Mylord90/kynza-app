import 'package:flutter/material.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../domain/onboarding_slide.dart';
import '../widgets/kynza_onboarding_next_button.dart';
import '../widgets/kynza_onboarding_progress.dart';
import '../widgets/onboarding_carousel_controller.dart';
import '../widgets/onboarding_crossfade_carousel.dart';

/// Onboarding screen 1 — full-bleed editorial photo carousel with a fixed
/// headline/subtitle, KYNZA's signature blob "next" button and a segmented
/// progress indicator.
///
/// Responsive strategy (breakpoint: [AppBreakpoints.tablet], matching
/// [KynzaAuthCard]'s existing large-screen convention): below the
/// breakpoint the carousel runs edge-to-edge; at or above it, the portrait
/// 9:16 composition is preserved and centered in a fixed-width panel on a
/// full-bleed black background, rather than stretching a portrait photo
/// across a landscape viewport.
class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  static const _panelWidth = 520.0;

  late final _carouselController = OnboardingCarouselController(
    slideCount: OnboardingSlides.all.length,
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
    final panelWidth = isLargeScreen ? _panelWidth : size.width;
    final cacheWidth = (panelWidth * MediaQuery.devicePixelRatioOf(context))
        .round();

    final content = Stack(
      fit: StackFit.expand,
      children: [
        OnboardingCrossfadeCarousel(
          slides: OnboardingSlides.all,
          controller: _carouselController,
          cacheWidth: cacheWidth,
        ),
        const _BottomScrim(),
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
                const _OnboardingHeadline(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.onboardingSubtitle,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: _carouselController,
                      builder: (context, _) => KynzaOnboardingProgress(
                        itemCount: _carouselController.slideCount,
                        currentIndex: _carouselController.currentIndex,
                        currentProgress: _carouselController.segmentProgress,
                      ),
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

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

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

class _OnboardingHeadline extends StatelessWidget {
  const _OnboardingHeadline();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text.rich(
      TextSpan(
        style: AppTypography.headlineLarge,
        children: [
          TextSpan(text: l10n.onboardingHeadlinePart1),
          TextSpan(
            text: l10n.onboardingHeadlineAccent,
            style: const TextStyle(color: AppColors.primary),
          ),
          TextSpan(text: l10n.onboardingHeadlinePart2),
        ],
      ),
    );
  }
}
