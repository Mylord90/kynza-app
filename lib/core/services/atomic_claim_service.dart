import 'dart:async';
import 'dart:math';

/// Reusable "claim before processing" guard for any pending-items queue
/// that a hot reconnect path can trigger concurrently. `KynzaOfflineBanner`
/// is mounted independently in ~40 screens and every mounted instance
/// calls the same flush method on the same connectivity flip — without
/// this guard, N mounted banners means N concurrent flushes of the same
/// queue, each reading the same pending snapshot before any of them
/// removes anything. [runExclusive] ensures only one body runs per [key]
/// at a time; a caller that arrives while another is already running
/// simply awaits that same in-flight run instead of starting a duplicate
/// one — the queue's own pending()/remove() cycle never needs to be
/// concurrency-safe itself. This is the client-side half of CP0's atomic
/// claim architecture (see docs/enterprise-resilience/CONCURRENCY_REPORT.md);
/// the server-side half is the `FOR UPDATE SKIP LOCKED` RPC pattern used
/// by `claim_pending_action_runs`.
class AtomicClaimService {
  AtomicClaimService._();
  static final AtomicClaimService instance = AtomicClaimService._();

  final Map<String, Future<void>> _inFlight = {};

  /// Runs [body] under the exclusive lock named [key]. If another call
  /// under the same [key] is already in flight, this returns that same
  /// future instead of starting a second run — the equivalent of a
  /// claim that only one caller can hold at a time.
  Future<void> runExclusive(String key, Future<void> Function() body) async {
    final existing = _inFlight[key];
    if (existing != null) {
      await existing;
      return;
    }
    final future = body();
    _inFlight[key] = future;
    try {
      await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Clears every held lock. A real app kill/restart wipes this
  /// in-memory map along with everything else in the process — only the
  /// Hive-backed queue data survives to disk — so this is what a test
  /// simulating "process restart" should call, not something reachable
  /// from normal app code.
  void reset() => _inFlight.clear();

  /// Exponential backoff with jitter for a queue item's next retry
  /// attempt, given its 1-based [attempt] count. Shared policy for every
  /// claim-based retry queue in the app (`MutationOutboxService`,
  /// `LegalAcceptanceQueueService`) so a failing item doesn't get
  /// retried on literally the very next reconnect event — capped at
  /// [maxDelay] so a long-failing item still gets retried at a bounded
  /// interval rather than backing off forever.
  static Duration backoffWithJitter(
    int attempt, {
    Duration base = const Duration(seconds: 30),
    Duration maxDelay = const Duration(minutes: 30),
    Random? random,
  }) {
    final exponent = attempt - 1 < 10 ? attempt - 1 : 10; // avoid overflow
    final exponential = base * pow(2, exponent).toInt();
    final capped = exponential > maxDelay ? maxDelay : exponential;
    final jitterMs = (random ?? Random()).nextInt(1000);
    return capped + Duration(milliseconds: jitterMs);
  }
}
