import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/services/circuit_breaker.dart';

void main() {
  group('CircuitBreaker state machine', () {
    test('starts closed and stays closed while calls succeed', () async {
      final breaker = CircuitBreaker(failureThreshold: 3);
      for (var i = 0; i < 5; i++) {
        final result = await breaker.run(() async => 'ok', () async => 'fallback');
        expect(result, 'ok');
      }
      expect(breaker.state, CircuitBreakerState.closed);
    });

    test('trips OPEN after failureThreshold consecutive failures', () async {
      final breaker = CircuitBreaker(failureThreshold: 3);
      for (var i = 0; i < 2; i++) {
        await breaker.run(() async => throw Exception('down'), () async => 'fallback');
        expect(breaker.state, CircuitBreakerState.closed, reason: 'below threshold yet');
      }
      final result = await breaker.run(() async => throw Exception('down'), () async => 'fallback');
      expect(result, 'fallback');
      expect(breaker.state, CircuitBreakerState.open);
    });

    test('while OPEN, action is never invoked — goes straight to fallback', () async {
      final breaker = CircuitBreaker(failureThreshold: 1);
      await breaker.run(() async => throw Exception('down'), () async => 'fallback');
      expect(breaker.state, CircuitBreakerState.open);

      var actionCalled = false;
      final result = await breaker.run(() async {
        actionCalled = true;
        return 'should not run';
      }, () async => 'fallback');

      expect(result, 'fallback');
      expect(actionCalled, isFalse, reason: 'OPEN must skip the action entirely');
    });

    test(
      'OPEN -> HALF_OPEN -> CLOSED: after openDuration elapses, calls are '
      'attempted again; enough consecutive successes closes the breaker',
      () async {
        final breaker = CircuitBreaker(
          failureThreshold: 1,
          openDuration: const Duration(milliseconds: 20),
          halfOpenSuccessThreshold: 2,
        );
        await breaker.run(() async => throw Exception('down'), () async => 'fallback');
        expect(breaker.state, CircuitBreakerState.open);

        await Future.delayed(const Duration(milliseconds: 30));
        expect(breaker.state, CircuitBreakerState.halfOpen, reason: 'openDuration elapsed');

        var actionCalls = 0;
        final r1 = await breaker.run(() async {
          actionCalls++;
          return 'ok';
        }, () async => 'fallback');
        expect(r1, 'ok', reason: 'HALF_OPEN must actually attempt the call');
        expect(breaker.state, CircuitBreakerState.halfOpen, reason: 'only 1 of 2 successes so far');

        final r2 = await breaker.run(() async {
          actionCalls++;
          return 'ok';
        }, () async => 'fallback');
        expect(r2, 'ok');
        expect(actionCalls, 2);
        expect(breaker.state, CircuitBreakerState.closed, reason: 'reached halfOpenSuccessThreshold');
      },
    );

    test('HALF_OPEN -> OPEN: a single failure while testing recovery re-opens immediately', () async {
      final breaker = CircuitBreaker(
        failureThreshold: 1,
        openDuration: const Duration(milliseconds: 10),
        halfOpenSuccessThreshold: 2,
      );
      await breaker.run(() async => throw Exception('down'), () async => 'fallback');
      await Future.delayed(const Duration(milliseconds: 15));
      expect(breaker.state, CircuitBreakerState.halfOpen);

      final result = await breaker.run(() async => throw Exception('still down'), () async => 'fallback');
      expect(result, 'fallback');
      expect(breaker.state, CircuitBreakerState.open, reason: 'a HALF_OPEN failure must re-open, not just decrement');
    });

    test('reset() forces a clean CLOSED state', () async {
      final breaker = CircuitBreaker(failureThreshold: 1);
      await breaker.run(() async => throw Exception('down'), () async => 'fallback');
      expect(breaker.state, CircuitBreakerState.open);
      breaker.reset();
      expect(breaker.state, CircuitBreakerState.closed);
    });

    test('run() never throws when action fails — fallback absorbs it', () async {
      final breaker = CircuitBreaker();
      final result = await breaker.run(
        () async => throw StateError('boom'),
        () async => 'safe-fallback',
      );
      expect(result, 'safe-fallback');
    });
  });
}
