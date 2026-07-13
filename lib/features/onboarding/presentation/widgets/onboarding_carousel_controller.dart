import 'package:flutter/foundation.dart';

/// Reports the carousel's current slide index and how far the active
/// segment has filled (0..1) — required by [OnboardingCrossfadeCarousel]'s
/// API so it always has somewhere to report per-frame progress, whether or
/// not the hosting screen's UI currently visualizes it. `KynzaOnboardingProgress`
/// no longer reads this: the onboarding flow's pagination now represents the
/// screen's position in the 3-screen flow, not the carousel's image rhythm.
///
/// A plain [ChangeNotifier] rather than a Riverpod provider deliberately:
/// this fires on every animation frame, and routing that through a
/// provider would rebuild every widget watching it. Riverpod is reserved
/// here for the precache readiness flag (`onboardingImagesReadyProvider`),
/// which changes once, not per-frame.
class OnboardingCarouselController extends ChangeNotifier {
  OnboardingCarouselController({required this.slideCount});

  final int slideCount;

  int currentIndex = 0;
  double segmentProgress = 0.0;

  void reportProgress(int index, double progress) {
    currentIndex = index;
    segmentProgress = progress;
    notifyListeners();
  }
}
