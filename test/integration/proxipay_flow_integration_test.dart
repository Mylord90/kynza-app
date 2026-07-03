import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/proxipay/proxipay_session_model.dart';
import 'package:kynza/features/proxipay/application/providers/proxipay_providers.dart';
import 'package:kynza/features/proxipay/domain/repositories/proxipay_repository.dart';

/// End-to-end (staff-creates -> client-scans -> client-confirms) coverage
/// for the ProxiPay flow, which had zero test coverage beyond a plain model
/// test before this phase (Phase 9, Enterprise Hardening pass). Exercises
/// the real `ProxiPayNotifier` against a fake repository, following this
/// repo's Riverpod-provider-override convention. ProxiPay is deliberately
/// fully online/session-based (no offline queue — see
/// docs/OFFLINE_STRATEGY.md), so there is no "airplane mode" variant here;
/// that's covered separately for the flows that do queue (see
/// test/integration/offline_airplane_mode_test.dart).
class _FakeProxiPayRepository implements ProxiPayRepository {
  final _sessions = <String, ProxiPaySessionModel>{};
  int confirmCallCount = 0;

  void seed(ProxiPaySessionModel session) => _sessions[session.id] = session;

  @override
  Future<ProxiPaySessionModel> createSession(String bookingId) async {
    final session = ProxiPaySessionModel(
      id: 'session-1',
      bookingId: bookingId,
      salonId: 'salon-1',
      staffId: 'staff-1',
      amountBif: 15000,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    _sessions[session.id] = session;
    return session;
  }

  @override
  Future<ProxiPaySessionModel?> getSession(String sessionId) async =>
      _sessions[sessionId];

  @override
  Future<void> confirmSession({
    required String sessionId,
    required String method,
    required String phone,
  }) async {
    confirmCallCount++;
    final existing = _sessions[sessionId];
    if (existing == null) throw Exception('session_not_found');
    if (existing.status != 'pending') {
      throw Exception('session_already_confirmed');
    }
    _sessions[sessionId] = existing.copyWith(status: 'confirmed');
  }

  @override
  Stream<ProxiPaySessionModel?> watchSession(String sessionId) =>
      Stream.value(_sessions[sessionId]);
}

ProviderContainer _container(ProxiPayRepository repo) {
  final container = ProviderContainer(
    overrides: [proxipayRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ProxiPay flow — staff creates, client confirms', () {
    test('full happy path: create -> get -> confirm -> status flips to confirmed', () async {
      final repo = _FakeProxiPayRepository();
      final container = _container(repo);
      final notifier = container.read(proxipayNotifierProvider.notifier);

      final created = await notifier.createSession('booking-1');
      expect(created.status, 'pending');
      expect(created.amountBif, 15000);

      final scanned = await notifier.getSession(created.id);
      expect(scanned, isNotNull);
      expect(scanned!.bookingId, 'booking-1');

      await notifier.confirmSession(
        sessionId: created.id,
        method: 'lumicash',
        phone: '+25779000000',
      );

      final after = await notifier.getSession(created.id);
      expect(after!.status, 'confirmed');
      expect(repo.confirmCallCount, 1);
    });

    test('confirming an expired/unknown session id throws, does not silently succeed', () async {
      final repo = _FakeProxiPayRepository();
      final container = _container(repo);
      final notifier = container.read(proxipayNotifierProvider.notifier);

      await expectLater(
        notifier.confirmSession(
          sessionId: 'never-created',
          method: 'lumicash',
          phone: '+25779000000',
        ),
        throwsA(anything),
      );
      expect(repo.confirmCallCount, 1);
    });
  });

  group('ProxiPay flow — replay protection', () {
    test('confirming the same session twice rejects the second call', () async {
      final repo = _FakeProxiPayRepository();
      final container = _container(repo);
      final notifier = container.read(proxipayNotifierProvider.notifier);

      final created = await notifier.createSession('booking-1');

      await notifier.confirmSession(
        sessionId: created.id,
        method: 'lumicash',
        phone: '+25779000000',
      );

      await expectLater(
        notifier.confirmSession(
          sessionId: created.id,
          method: 'lumicash',
          phone: '+25779000000',
        ),
        throwsA(
          predicate((e) => e.toString().contains('session_already_confirmed')),
        ),
      );
      expect(repo.confirmCallCount, 2);
    });
  });

  group('ProxiPay flow — realtime watch reflects confirmation', () {
    test('watchSession stream reflects the post-confirm state', () async {
      final repo = _FakeProxiPayRepository();
      final container = _container(repo);
      final notifier = container.read(proxipayNotifierProvider.notifier);

      final created = await notifier.createSession('booking-1');
      await notifier.confirmSession(
        sessionId: created.id,
        method: 'lumicash',
        phone: '+25779000000',
      );

      final watched = await container.read(
        proxipaySessionStreamProvider(created.id).future,
      );
      expect(watched?.status, 'confirmed');
    });
  });
}
