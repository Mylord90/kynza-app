import 'package:flutter/services.dart';

abstract class KynzaHaptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.vibrate();
  static void warning() => HapticFeedback.heavyImpact();
}
