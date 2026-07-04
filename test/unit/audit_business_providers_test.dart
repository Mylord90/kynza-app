import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/evolution/audit_business/application/providers/audit_business_providers.dart';
import 'package:kynza/features/evolution/audit_business/domain/repositories/audit_business_repository.dart';

class _FakeAuditBusinessRepository implements AuditBusinessRepository {
  @override
  Future<List<Map<String, dynamic>>> getSecurityTrail() async => [
    {'type_action': 'user_login', 'severity': 'info'},
  ];

  @override
  Future<List<Map<String, dynamic>>> getRgpdTrail() async => [];

  @override
  Future<List<Map<String, dynamic>>> getFraudProxipay() async => [
    {'anomaly_type': 'duplicate_sessions_per_booking', 'occurrence_count': 2},
  ];

  @override
  Future<List<Map<String, dynamic>>> getFinancialAccounting() async => [];

  @override
  Future<List<Map<String, dynamic>>> getUserBehavior() async => [];

  @override
  Future<List<Map<String, dynamic>>> getSalonPerformance() async => [];

  @override
  Future<List<Map<String, dynamic>>> getCommissionAccuracy() async => [];

  @override
  Future<List<Map<String, dynamic>>> getAutomationExecution() async => [];
}

void main() {
  group(
    'Audit Business providers (Phase 10 — Track A views, real data only)',
    () {
      test('security trail surfaces exactly what the repository returns', () async {
        final container = ProviderContainer(
          overrides: [
            auditBusinessRepositoryProvider.overrideWithValue(
              _FakeAuditBusinessRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final rows = await container.read(auditSecurityTrailProvider.future);

        expect(rows.single['type_action'], 'user_login');
      });

      test('an empty RGPD trail surfaces as an empty list, not an error', () async {
        final container = ProviderContainer(
          overrides: [
            auditBusinessRepositoryProvider.overrideWithValue(
              _FakeAuditBusinessRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final rows = await container.read(auditRgpdTrailProvider.future);

        expect(rows, isEmpty);
      });

      test('fraud anomaly rows are surfaced verbatim from the repository', () async {
        final container = ProviderContainer(
          overrides: [
            auditBusinessRepositoryProvider.overrideWithValue(
              _FakeAuditBusinessRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final rows = await container.read(auditFraudProxipayProvider.future);

        expect(rows.single['anomaly_type'], 'duplicate_sessions_per_booking');
        expect(rows.single['occurrence_count'], 2);
      });
    },
  );
}
