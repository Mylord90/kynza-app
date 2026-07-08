import 'package:flutter/foundation.dart';

/// Reports the carousel's current slide index and how far the active
/// segment has filled (0..1) — read by [KynzaOnboardingProgress] via
/// `AnimatedBuilder` so only the progress bar repaints on each tick, not
/// the rest of the screen.
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
