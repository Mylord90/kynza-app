import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/evolution/health_center/application/providers/health_center_providers.dart';
import 'package:kynza/features/evolution/health_center/domain/repositories/health_center_repository.dart';

class _FakeHealthCenterRepository implements HealthCenterRepository {
  _FakeHealthCenterRepository({this.notificationRows = const []});

  final List<Map<String, dynamic>> notificationRows;

  @override
  Future<List<Map<String, dynamic>>> getSupabaseDashboard() async => [
    {'table_count': 55, 'policy_count': 132},
  ];

  @override
  Future<List<Map<String, dynamic>>> getStorageDashboard() async => [];

  @override
  Future<List<Map<String, dynamic>>> getNotificationDashboard() async =>
      notificationRows;

  @override
  Future<List<Map<String, dynamic>>> getQueueDashboard() async => [];

  @override
  Future<List<Map<String, dynamic>>> getEdgeFunctionDashboard() async => [];

  @override
  Future<List<Map<String, dynamic>>> getCrashDashboard() async => [];

  @override
  Future<List<Map<String, dynamic>>> getSecurityDashboard() async => [];
}

void main() {
  group(
    'Health Center dashboard providers (Phase 5 — composition, not duplication)',
    () {
      test(
        'supabaseDashboardProvider surfaces the real row from the repository, '
        'not mock data hardcoded in the provider itself',
        () async {
          final container = ProviderContainer(
            overrides: [
              healthCenterRepositoryProvider.overrideWithValue(
                _FakeHealthCenterRepository(),
              ),
            ],
          );
          addTearDown(container.dispose);

          final rows = await container.read(supabaseDashboardProvider.future);

          expect(rows, hasLength(1));
          expect(rows.single['table_count'], 55);
        },
      );

      test(
        'a genuinely empty result (no rows) surfaces as an empty list, not '
        'an error — the honest "awaiting data" UI state',
        () async {
          final container = ProviderContainer(
            overrides: [
              healthCenterRepositoryProvider.overrideWithValue(
                _FakeHealthCenterRepository(),
              ),
            ],
          );
          addTearDown(container.dispose);

          final rows = await container.read(storageDashboardProvider.future);

          expect(rows, isEmpty);
        },
      );

      test('notificationDashboardProvider reflects whatever the repository returns', () async {
        final container = ProviderContainer(
          overrides: [
            healthCenterRepositoryProvider.overrideWithValue(
              _FakeHealthCenterRepository(
                notificationRows: [
                  {'channel': 'push', 'total_sent': 10, 'delivered_count': 9},
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final rows = await container.read(notificationDashboardProvider.future);

        expect(rows.single['total_sent'], 10);
      });
    },
  );
}
