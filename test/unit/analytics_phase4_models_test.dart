import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/analytics/churn_risk_model.dart';
import 'package:kynza/core/models/analytics/client_ltv_model.dart';
import 'package:kynza/core/models/analytics/cohort_retention_model.dart';
import 'package:kynza/core/models/audit_log_model.dart';

void main() {
  group('ClientLtvModel.fromSupabase', () {
    test('parses snake_case columns into the model fields', () {
      final model = ClientLtvModel.fromSupabase({
        'salon_id': 's1',
        'client_id': 'c1',
        'client_name': 'Jeanne',
        'visit_count': 4,
        'total_spent_bif': 50000,
        'first_visit_at': '2026-01-01T10:00:00.000Z',
        'last_visit_at': '2026-06-01T10:00:00.000Z',
      });
      expect(model.clientName, 'Jeanne');
      expect(model.visitCount, 4);
      expect(model.totalSpentBif, 50000);
    });
  });

  group('ChurnRiskModel.fromSupabase', () {
    test('parses risk_level and days_since_last_visit', () {
      final model = ChurnRiskModel.fromSupabase({
        'salon_id': 's1',
        'client_id': 'c1',
        'client_name': 'Eric',
        'last_visit_at': '2026-04-01T10:00:00.000Z',
        'days_since_last_visit': 60,
        'risk_level': 'high',
      });
      expect(model.riskLevel, 'high');
      expect(model.daysSinceLastVisit, 60);
    });
  });

  group('CohortRetentionModelX.retentionPct', () {
    test('returns the retained fraction of the cohort', () {
      final model = CohortRetentionModel(
        cohortMonth: DateTime(2026, 1, 1),
        monthOffset: 1,
        cohortSize: 10,
        retainedCount: 4,
      );
      expect(model.retentionPct, closeTo(0.4, 0.0001));
    });

    test(
      'returns 0.0 when the cohort is empty (guard against divide-by-zero)',
      () {
        final model = CohortRetentionModel(
          cohortMonth: DateTime(2026, 1, 1),
          monthOffset: 1,
          cohortSize: 0,
          retainedCount: 0,
        );
        expect(model.retentionPct, 0.0);
      },
    );

    test('clamps at 1.0 when retainedCount somehow exceeds cohortSize', () {
      final model = CohortRetentionModel(
        cohortMonth: DateTime(2026, 1, 1),
        monthOffset: 1,
        cohortSize: 5,
        retainedCount: 7,
      );
      expect(model.retentionPct, 1.0);
    });
  });

  group('auditLogCategoryFor', () {
    test('maps booking_* to booking', () {
      expect(auditLogCategoryFor('booking_created'), 'booking');
      expect(auditLogCategoryFor('booking_no_show'), 'booking');
    });

    test('maps payment_* and refund_* to payment', () {
      expect(auditLogCategoryFor('payment_completed'), 'payment');
      expect(auditLogCategoryFor('refund_initiated'), 'payment');
    });

    test('maps staff_* to staff', () {
      expect(auditLogCategoryFor('staff_invited'), 'staff');
      expect(auditLogCategoryFor('staff_invitation_accepted'), 'staff');
    });

    test('falls back to settings for everything else', () {
      expect(auditLogCategoryFor('salon_updated'), 'settings');
      expect(auditLogCategoryFor('referral_claimed'), 'settings');
    });
  });
}
