import 'package:flutter/animation.dart';

/// Standardized easing curves — pairs with [AppDurations]. No screen should
/// hand-pick a one-off `Curves.*` value outside of this set (consistency
/// across Phase A's transitions/entrance animations).
abstract class AppCurves {
  static const standard = Curves.easeInOutCubic;
  static const decelerate = Curves.easeOutCubic;
  static const accelerate = Curves.easeInCubic;
  static const spring = Curves.elasticOut;
  static const sharp = Curves.easeInOutQuart;
}
