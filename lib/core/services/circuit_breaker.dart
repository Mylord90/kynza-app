/// CP2 (Enterprise Resilience & Reliability Certification) — a reusable
/// circuit breaker for any external dependency call (Supabase, FCM, ...).
/// Standard three-state machine:
///
/// - [CircuitBreakerState.closed] — calls go through normally. A run of
///   consecutive failures reaching [failureThreshold] trips the breaker to
///   `open`.
/// - [CircuitBreakerState.open] — calls are NOT attempted; [run] goes
///   straight to `fallback` (fail fast, don't hammer a dependency that's
///   already known to be down). After [openDuration] has elapsed, the next
///   call transitions to `halfOpen` to test recovery.
/// - [CircuitBreakerState.halfOpen] — the next [halfOpenSuccessThreshold]
///   consecutive calls are attempted for real; enough successes closes the
///   breaker again, a single failure re-opens it immediately.
///
/// [run] always calls `fallback` when `action` doesn't complete — whether
/// because the breaker was already open (skipped entirely) or because this
/// particular call just failed. This is a deliberate choice for this
/// codebase: CP1 (docs/enterprise-resilience/RESILIENCE_REPORT.md §1) found
/// that every offline-queueable write treated "Supabase erroring" as a bare
/// error instead of falling back to the offline queue — the fix is for
/// every dependency failure (not just sustained ones) to invoke the same
/// safe fallback a caller would use if it already knew the dependency was
/// down. The breaker's state machine still matters: it's what lets [run]
/// skip a doomed network call entirely once failures have accumulated,
/// instead of waiting out a real timeout on every single call.
enum CircuitBreakerState { closed, open, halfOpen }

class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 30),
    this.halfOpenSuccessThreshold = 2,
  });

  final int failureThreshold;
  final Duration openDuration;
  final int halfOpenSuccessThreshold;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _consecutiveFailures = 0;
  int _halfOpenSuccesses = 0;
  DateTime? _openedAt;

  /// Reads (and lazily advances) the current state — an `open` breaker
  /// whose [openDuration] has elapsed becomes `halfOpen` on read, the same
  /// way a real breaker only knows it's time to test recovery when
  /// something asks.
  CircuitBreakerState get state {
    if (_state == CircuitBreakerState.open &&
        _openedAt != null &&
        DateTime.now().isAfter(_openedAt!.add(openDuration))) {
      _state = CircuitBreakerState.halfOpen;
      _halfOpenSuccesses = 0;
    }
    return _state;
  }

  /// Runs [action] if the breaker allows it, otherwise (open, or [action]
  /// itself throws) runs [fallback] instead. Never throws unless [fallback]
  /// itself throws.
  Future<T> run<T>(
    Future<T> Function() action,
    Future<T> Function() fallback,
  ) async {
    if (state == CircuitBreakerState.open) {
      return fallback();
    }
    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (_) {
      _onFailure();
      return fallback();
    }
  }

  void _onSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenSuccesses++;
      if (_halfOpenSuccesses >= halfOpenSuccessThreshold) {
        _state = CircuitBreakerState.closed;
        _consecutiveFailures = 0;
      }
    } else {
      _consecutiveFailures = 0;
    }
  }

  void _onFailure() {
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.open;
      _openedAt = DateTime.now();
      return;
    }
    _consecutiveFailures++;
    if (_consecutiveFailures >= failureThreshold) {
      _state = CircuitBreakerState.open;
      _openedAt = DateTime.now();
    }
  }

  /// Test-only: forces the breaker back to a clean `closed` state.
  void reset() {
    _state = CircuitBreakerState.closed;
    _consecutiveFailures = 0;
    _halfOpenSuccesses = 0;
    _openedAt = null;
  }
}

/// Named, app-wide circuit breaker instances — one per external dependency,
/// per CP2's priority list (Supabase and FCM are the riskiest per CP1).
/// A single shared instance per dependency (not one per call site) is what
/// lets a run of failures in one write path (e.g. review creation) also
/// protect the next one (e.g. profile update) from hammering the same
/// down dependency.
class DependencyCircuitBreakers {
  DependencyCircuitBreakers._();

  static final supabase = CircuitBreaker();
  static final fcm = CircuitBreaker();
}
