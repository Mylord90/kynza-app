import 'package:firebase_performance/firebase_performance.dart';

/// Thin wrapper over Firebase Performance Monitoring — named custom traces
/// on top of the SDK's automatic app-start/network traces. Kept static and
/// no-DI, matching CrashReportingService's shape.
abstract class PerformanceMonitoringService {
  static final _performance = FirebasePerformance.instance;

  static Trace? _coldStartTrace;

  /// Started as early as possible in `main()`.
  static Future<void> startColdStartTrace() async {
    final trace = _performance.newTrace('cold_start');
    _coldStartTrace = trace;
    await trace.start();
  }

  /// Stopped once the very first auth check resolves (AuthBootGate's
  /// loading → data/error transition) — the point the app is actually
  /// usable, not just rendered.
  static Future<void> stopColdStartTrace() async {
    final trace = _coldStartTrace;
    _coldStartTrace = null;
    await trace?.stop();
  }

  /// Wraps [action] in a named trace, started before and stopped after
  /// regardless of success/failure — a failed action still reports timing,
  /// since a slow failure is as worth measuring as a slow success.
  static Future<T> traceAsync<T>(
    String name,
    Future<T> Function() action,
  ) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    try {
      return await action();
    } finally {
      await trace.stop();
    }
  }
}
