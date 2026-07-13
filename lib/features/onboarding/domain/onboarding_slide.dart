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

  /// The 4 slides for onboarding screen 2, in the imposed display order.
  static const screen2 = [
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen2/webp/slide2_1.webp',
      lqipAsset: 'assets/onboarding/screen2/lqip/slide2_1_lqip.webp',
      alignment: Alignment(0, -0.15),
      kenBurnsDriftDirection: 1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen2/webp/slide2_2.webp',
      lqipAsset: 'assets/onboarding/screen2/lqip/slide2_2_lqip.webp',
      alignment: Alignment(0, -0.2),
      kenBurnsDriftDirection: -1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen2/webp/slide2_3.webp',
      lqipAsset: 'assets/onboarding/screen2/lqip/slide2_3_lqip.webp',
      alignment: Alignment(0, -0.05),
      kenBurnsDriftDirection: 0,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen2/webp/slide2_4.webp',
      lqipAsset: 'assets/onboarding/screen2/lqip/slide2_4_lqip.webp',
      alignment: Alignment(0, -0.15),
      kenBurnsDriftDirection: 1,
    ),
  ];

  /// The 3 slides for onboarding screen 3 (the final CTA screen), in the
  /// imposed display order.
  static const screen3 = [
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen3/webp/slide3_1.webp',
      lqipAsset: 'assets/onboarding/screen3/lqip/slide3_1_lqip.webp',
      alignment: Alignment(0, -0.15),
      kenBurnsDriftDirection: 1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen3/webp/slide3_2.webp',
      lqipAsset: 'assets/onboarding/screen3/lqip/slide3_2_lqip.webp',
      alignment: Alignment(0, -0.2),
      kenBurnsDriftDirection: -1,
    ),
    OnboardingSlide(
      webpAsset: 'assets/onboarding/screen3/webp/slide3_3.webp',
      lqipAsset: 'assets/onboarding/screen3/lqip/slide3_3_lqip.webp',
      alignment: Alignment(0, -0.05),
      kenBurnsDriftDirection: 0,
    ),
  ];
}
