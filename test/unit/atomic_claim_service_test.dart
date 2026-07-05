import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/services/atomic_claim_service.dart';

void main() {
  setUp(AtomicClaimService.instance.reset);
  tearDown(AtomicClaimService.instance.reset);

  group('AtomicClaimService.runExclusive', () {
    test('a second call under the same key while the first is still running '
        'awaits the first instead of starting a duplicate run', () async {
      var runCount = 0;
      final gate = Completer<void>();

      final first = AtomicClaimService.instance.runExclusive('k', () async {
        runCount++;
        await gate.future;
      });
      final second = AtomicClaimService.instance.runExclusive('k', () async {
        runCount++;
      });

      gate.complete();
      await Future.wait([first, second]);

      expect(runCount, 1, reason: 'the second call must not have run its own body');
    });

    test('different keys run independently, concurrently', () async {
      final order = <String>[];
      final gateA = Completer<void>();

      final a = AtomicClaimService.instance.runExclusive('a', () async {
        await gateA.future;
        order.add('a');
      });
      final b = AtomicClaimService.instance.runExclusive('b', () async {
        order.add('b');
      });

      await b; // 'b' completes without waiting for 'a's key.
      expect(order, ['b']);
      gateA.complete();
      await a;
      expect(order, ['b', 'a']);
    });

    test('a call after the first completes runs its own body again', () async {
      var runCount = 0;
      await AtomicClaimService.instance.runExclusive('k', () async {
        runCount++;
      });
      await AtomicClaimService.instance.runExclusive('k', () async {
        runCount++;
      });
      expect(runCount, 2);
    });

    test('an exception in the body propagates to the caller and releases the lock', () async {
      await expectLater(
        AtomicClaimService.instance.runExclusive('k', () async {
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );
      // Lock was released despite the throw — a subsequent call runs normally.
      var ran = false;
      await AtomicClaimService.instance.runExclusive('k', () async {
        ran = true;
      });
      expect(ran, isTrue);
    });
  });

  group('AtomicClaimService.backoffWithJitter', () {
    test('grows exponentially with attempt count, before the cap', () {
      final random = Random(1);
      final d1 = AtomicClaimService.backoffWithJitter(1, random: random);
      final d2 = AtomicClaimService.backoffWithJitter(2, random: random);
      final d3 = AtomicClaimService.backoffWithJitter(3, random: random);
      expect(d2.inMilliseconds, greaterThan(d1.inMilliseconds));
      expect(d3.inMilliseconds, greaterThan(d2.inMilliseconds));
    });

    test('is capped at maxDelay for a large attempt count', () {
      final random = Random(1);
      final d = AtomicClaimService.backoffWithJitter(
        50,
        maxDelay: const Duration(minutes: 5),
        random: random,
      );
      // Capped duration + up to 999ms of jitter.
      expect(d.inMilliseconds, lessThanOrEqualTo(const Duration(minutes: 5).inMilliseconds + 999));
      expect(d.inMilliseconds, greaterThanOrEqualTo(const Duration(minutes: 5).inMilliseconds));
    });

    test('adds jitter so the same attempt is not always identical', () {
      final values = {
        for (var i = 0; i < 20; i++)
          AtomicClaimService.backoffWithJitter(1, random: Random(i)).inMilliseconds,
      };
      expect(values.length, greaterThan(1), reason: 'jitter should vary the delay across seeds');
    });
  });
}
