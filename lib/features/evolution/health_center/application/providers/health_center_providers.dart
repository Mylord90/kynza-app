import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/app_providers.dart';
import '../../../../../core/services/mutation_outbox_service.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../data/repositories/health_center_repository_impl.dart';
import '../../domain/repositories/health_center_repository.dart';

final healthCenterRepositoryProvider = Provider<HealthCenterRepository>(
  (ref) => HealthCenterRepositoryImpl(),
);

final supabaseDashboardProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(healthCenterRepositoryProvider).getSupabaseDashboard(),
);

final storageDashboardProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(healthCenterRepositoryProvider).getStorageDashboard(),
);

final notificationDashboardProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) =>
          ref.read(healthCenterRepositoryProvider).getNotificationDashboard(),
    );

final queueDashboardProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(healthCenterRepositoryProvider).getQueueDashboard(),
);

final edgeFunctionDashboardProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) =>
          ref.read(healthCenterRepositoryProvider).getEdgeFunctionDashboard(),
    );

final crashDashboardProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(healthCenterRepositoryProvider).getCrashDashboard(),
);

final securityDashboardProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(healthCenterRepositoryProvider).getSecurityDashboard(),
);

/// Sync Dashboard — genuinely client-only: the outbox/DLQ live in Hive, not
/// Postgres, so there is no SQL view to back this one (documented in
/// PHASE_2_OBSERVABILITY.md rather than inventing a fake server-side view).
final syncDashboardProvider = Provider<({int pendingCount, int deadLetterCount})>((
  ref,
) {
  final outbox = MutationOutboxService();
  return (
    pendingCount: outbox.pending().length,
    deadLetterCount: outbox.deadLetterItems().length,
  );
});

/// Realtime Dashboard — this client's own channel connection state only, not
/// a fleet-wide view (Supabase's platform-level Realtime health isn't
/// exposed to a Flutter client at all — documented in
/// PHASE_2_OBSERVABILITY.md).
final realtimeChannelStatusProvider = Provider<String>((ref) {
  final status = SupabaseService.client.realtime.connState;
  return status.toString();
});

/// Network Dashboard — reuses the existing app-wide connectivityProvider
/// rather than a second connectivity pipeline.
final networkDashboardProvider = Provider<AsyncValue<bool>>(
  (ref) => ref.watch(connectivityProvider),
);

/// Performance Dashboard — Firebase Performance Monitoring has no in-app
/// read API (Console-only, same structural limitation as Crashlytics before
/// this phase's dual-log workaround). Returns null to signal "genuinely no
/// data source exists yet", rendered as an honest empty state, not a fake
/// metric.
final performanceDashboardProvider = Provider<Null>((ref) => null);
