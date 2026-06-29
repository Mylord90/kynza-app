import 'package:flutter/material.dart';
import '../constants/app_curves.dart';
import '../constants/app_durations.dart';

/// Reusable entrance animations — wrap a widget once, no per-screen
/// AnimationController boilerplate. Built on [AppDurations]/[AppCurves] so
/// every screen that adopts these stays visually consistent.
abstract class KynzaAnimations {
  static Widget fadeSlideIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = AppDurations.rich,
    Offset beginOffset = const Offset(0, 0.08),
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(child),
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: AppCurves.decelerate,
      ),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: beginOffset * (1 - value) * 100,
          child: child,
        ),
      ),
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = AppDurations.medium,
    double beginScale = 0.92,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(child),
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: AppCurves.spring,
      ),
      builder: (context, value, _) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(
          scale: beginScale + (1 - beginScale) * value.clamp(0, 1),
          child: child,
        ),
      ),
    );
  }

  /// A single shimmer pass over [child] — distinct from [KynzaSkeleton]
  /// (which is a placeholder *for* content); this is a one-shot highlight
  /// sweep used to draw attention to content that just finished loading.
  static Widget shimmerPulse({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: AppDurations.rich,
      curve: AppCurves.decelerate,
      builder: (context, value, _) => Opacity(opacity: value, child: child),
    );
  }
}
