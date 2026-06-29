import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/staff_commission_model.dart';
import 'package:kynza/core/models/staff_profile_model.dart';

void main() {
  group('StaffCommissionModelX.isPaid', () {
    test('true when status is paid', () {
      const commission = StaffCommissionModel(
        staffId: 's1',
        salonId: 'salon1',
        bookingId: 'b1',
        rateType: 'percent',
        rateValue: 10,
        amountBif: 5000,
        status: 'paid',
      );
      expect(commission.isPaid, isTrue);
    });

    test('false when status is pending (the default)', () {
      const commission = StaffCommissionModel(
        staffId: 's1',
        salonId: 'salon1',
        bookingId: 'b1',
        rateType: 'fixed',
        rateValue: 2000,
        amountBif: 2000,
      );
      expect(commission.isPaid, isFalse);
      expect(commission.status, 'pending');
    });
  });

  group('CommissionSummary', () {
    test('defaults every field to zero', () {
      const summary = CommissionSummary();
      expect(summary.earnedBif, 0);
      expect(summary.paidBif, 0);
      expect(summary.pendingBif, 0);
    });

    test('holds the values it is constructed with', () {
      const summary = CommissionSummary(
        earnedBif: 10000,
        paidBif: 6000,
        pendingBif: 4000,
      );
      expect(summary.earnedBif, 10000);
      expect(summary.paidBif, 6000);
      expect(summary.pendingBif, 4000);
    });
  });

  group('StaffProfileModel commission defaults', () {
    test('defaults to percent type with a zero rate', () {
      const staff = StaffProfileModel(salonId: 'salon1', displayName: 'Eric');
      expect(staff.commissionType, 'percent');
      expect(staff.commissionRate, 0);
    });
  });
}
