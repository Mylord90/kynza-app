import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/proxipay/proxipay_session_model.dart';

void main() {
  group('ProxiPaySessionModel', () {
    test('fromSupabase parses a pending row', () {
      final session = ProxiPaySessionModel.fromSupabase({
        'id': 'session-1',
        'booking_id': 'booking-1',
        'salon_id': 'salon-1',
        'staff_id': 'staff-1',
        'client_id': null,
        'amount_bif': 15000,
        'status': 'pending',
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 3))
            .toIso8601String(),
        'confirmed_at': null,
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(session.id, 'session-1');
      expect(session.amountBif, 15000);
      expect(session.clientId, isNull);
      expect(session.isPending, isTrue);
      expect(session.isConfirmed, isFalse);
    });

    test('isPending is false once expires_at is in the past', () {
      final session = ProxiPaySessionModel.fromSupabase({
        'id': 'session-2',
        'booking_id': 'booking-1',
        'salon_id': 'salon-1',
        'staff_id': 'staff-1',
        'amount_bif': 5000,
        'status': 'pending',
        'expires_at': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      });

      expect(session.isPending, isFalse);
      expect(session.isExpired, isTrue);
    });

    test('isConfirmed reflects a confirmed row', () {
      final session = ProxiPaySessionModel.fromSupabase({
        'id': 'session-3',
        'booking_id': 'booking-1',
        'salon_id': 'salon-1',
        'staff_id': 'staff-1',
        'client_id': 'client-1',
        'amount_bif': 8000,
        'status': 'confirmed',
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 3))
            .toIso8601String(),
        'confirmed_at': DateTime.now().toIso8601String(),
      });

      expect(session.isConfirmed, isTrue);
      expect(session.isPending, isFalse);
    });
  });
}
