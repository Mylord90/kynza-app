import 'package:flutter/widgets.dart';

/// One editorial photo in the onboarding carousel.
///
/// [kenBurnsDriftDirection] alternates across slides (1 = drift up,
/// -1 = drift down, 0 = zoom only) so the Ken Burns effect never reads as
/// mechanically repetitive — see KynzaKenBurnsImage.
class OnboardingSlide {
  const OnboardingSlide({
    required this.webpAsset,
    required this.lqipAsset,
    required this.alignment,
    required this.kenBurnsDriftDirection,
  });

  final String webpAsset;
  final String lqipAsset;
  final Alignment alignment;
  final double kenBurnsDriftDirection;
}

/// The 4 slides for onboarding screen 1, in the imposed display order:
/// barber, braids (hero), spa, nails.
abstract class OnboardingSlides {
  static const all = [
    OnboardingSlide(
      webpAsset: 'assets/onboarding/webp/slide_1_barber.webp',
      lqipAsset: 'assets/onboarding/lqip/slide_1_barber_lqip.webp',
      alignment: Alignment(0, -0.15),
      kenBurnsDriftDirection: 1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/webp/slide_2_braids.webp',
      lqipAsset: 'assets/onboarding/lqip/slide_2_braids_lqip.webp',
      alignment: Alignment(0, -0.2),
      kenBurnsDriftDirection: -1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/webp/slide_3_spa.webp',
      lqipAsset: 'assets/onboarding/lqip/slide_3_spa_lqip.webp',
      alignment: Alignment(0, -0.05),
      kenBurnsDriftDirection: 0,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/webp/slide_4_nails.webp',
      lqipAsset: 'assets/onboarding/lqip/slide_4_nails_lqip.webp',
      alignment: Alignment(0, -0.15),
      kenBurnsDriftDirection: 1,
    ),
  ];
}
