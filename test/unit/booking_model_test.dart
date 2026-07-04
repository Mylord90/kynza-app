import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/booking_model.dart';

BookingModel _booking({
  BookingStatus status = BookingStatus.pendingPayment,
  PaymentStatus paymentStatus = PaymentStatus.pending,
}) => BookingModel(
  salonId: 'salon1',
  clientId: 'client1',
  practitionerId: 'staff1',
  serviceId: 'service1',
  status: status,
  startTime: DateTime(2026, 1, 1, 10),
  endTime: DateTime(2026, 1, 1, 11),
  bufferEndTime: DateTime(2026, 1, 1, 11, 15),
  amountBif: 15000,
  paymentStatus: paymentStatus,
);

void main() {
  group('BookingModelX.isPaid', () {
    test('true when paymentStatus is completed', () {
      expect(
        _booking(paymentStatus: PaymentStatus.completed).isPaid,
        isTrue,
      );
    });

    test('false for every other payment status', () {
      for (final s in PaymentStatus.values.where(
        (s) => s != PaymentStatus.completed,
      )) {
        expect(_booking(paymentStatus: s).isPaid, isFalse, reason: s.name);
      }
    });
  });

  group('BookingModelX.isActive', () {
    test('true when confirmed or in progress', () {
      expect(_booking(status: BookingStatus.confirmed).isActive, isTrue);
      expect(_booking(status: BookingStatus.inProgress).isActive, isTrue);
    });

    test('false for pending/completed/cancelled/no-show', () {
      for (final s in [
        BookingStatus.pendingPayment,
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.noShow,
      ]) {
        expect(_booking(status: s).isActive, isFalse, reason: s.name);
      }
    });
  });

  group('BookingModelX.canCancel', () {
    test('true when pending payment or confirmed', () {
      expect(_booking(status: BookingStatus.pendingPayment).canCancel, isTrue);
      expect(_booking(status: BookingStatus.confirmed).canCancel, isTrue);
    });

    test('false once in progress, completed, cancelled, or no-show', () {
      for (final s in [
        BookingStatus.inProgress,
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.noShow,
      ]) {
        expect(_booking(status: s).canCancel, isFalse, reason: s.name);
      }
    });
  });

  group('BookingModelX.statusLabel', () {
    test('has a distinct French label for every status', () {
      final labels = BookingStatus.values.map((s) => _booking(status: s).statusLabel).toSet();
      expect(labels.length, BookingStatus.values.length);
    });
  });

  group('BookingModelX.statusColor', () {
    test('resolves without throwing for every status', () {
      for (final s in BookingStatus.values) {
        expect(() => _booking(status: s).statusColor, returnsNormally);
      }
    });
  });

  group('BookingStatusConverter', () {
    const converter = BookingStatusConverter();

    test('round-trips every status through its DB string', () {
      const expected = {
        BookingStatus.pendingPayment: 'pending_payment',
        BookingStatus.confirmed: 'confirmed',
        BookingStatus.inProgress: 'in_progress',
        BookingStatus.completed: 'completed',
        BookingStatus.cancelled: 'cancelled',
        BookingStatus.noShow: 'no_show',
      };
      for (final entry in expected.entries) {
        expect(converter.toJson(entry.key), entry.value);
        expect(converter.fromJson(entry.value), entry.key);
      }
    });

    test('falls back to the first status for an unknown DB string', () {
      expect(converter.fromJson('some_unknown_value'), BookingStatus.pendingPayment);
    });
  });

  group('PaymentStatusConverter', () {
    const converter = PaymentStatusConverter();

    test('round-trips every status through its enum name', () {
      for (final s in PaymentStatus.values) {
        expect(converter.toJson(s), s.name);
        expect(converter.fromJson(s.name), s);
      }
    });

    test('falls back to pending for an unknown DB string', () {
      expect(converter.fromJson('not_a_real_status'), PaymentStatus.pending);
    });
  });
}
