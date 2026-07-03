import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

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

  /// Unchanged signature — kept exactly as before so every existing tear-off
  /// call site (`.catchError(CrashReportingService.recordError)` and
  /// similar) keeps type-checking. Use [recordErrorForSalon] instead at
  /// call sites that have salon context and should also feed the Backend
  /// Enterprise Completion Phase 2 Crash Dashboard.
  static void recordError(Object error, StackTrace? stack) =>
      FirebaseCrashlytics.instance.recordError(error, stack);

  /// Same as [recordError], plus a best-effort dual-log to `activity_logs`
  /// for `v_crash_dashboard`/`get_crash_dashboard()` — Firebase Crashlytics
  /// itself has no in-app read API (Console-only), so this is the only way
  /// to show real crash-adjacent data inside the app. Only a handful of
  /// representative call sites use this today (see
  /// `docs/backend-completion/PHASE_2_OBSERVABILITY.md` for the exact list
  /// and the honest reason the remaining call sites aren't retrofitted in
  /// this pass) — the rest keep calling plain [recordError].
  static void recordErrorForSalon(
    Object error,
    StackTrace? stack,
    String salonId,
  ) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    _dualLogToActivityLogs(salonId, error, severity: 'error');
  }

  static Future<void> _dualLogToActivityLogs(
    String salonId,
    Object error, {
    required String severity,
  }) async {
    try {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return;
      await SupabaseService.from('activity_logs').insert({
        'salon_id': salonId,
        'user_id': userId,
        'type_action': 'client_error_logged',
        'severity': severity,
        'new_values': {'error': error.toString()},
      });
    } catch (_) {
      // Never escalate a failed audit write into another recordError call —
      // that would risk a feedback loop with this very method.
    }
  }
}
