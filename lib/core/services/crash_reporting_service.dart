import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashReportingService {
  static Future<void> init() async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void setUser(String userId, String role) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
    FirebaseCrashlytics.instance.setCustomKey('role', role);
  }

  static void log(String message) => FirebaseCrashlytics.instance.log(message);

  static void recordError(Object error, StackTrace? stack) =>
      FirebaseCrashlytics.instance.recordError(error, stack);
}
