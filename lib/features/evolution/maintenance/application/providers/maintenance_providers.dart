import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/maintenance_window_model.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepositoryImpl(),
);

// Non-autoDispose: persists so the router can always read its cached state.
// Invalidated by MaintenanceScreen's periodic timer (every 30 s) so the
// router redirect fires again when maintenance ends.
final maintenanceStatusProvider = FutureProvider<MaintenanceWindowModel?>((
  ref,
) {
  return ref.read(maintenanceRepositoryProvider).checkMaintenance();
});

/// Admin-only (P3-11, Master Plan Execution CP3).
final upcomingMaintenanceWindowsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
      return ref.read(maintenanceRepositoryProvider).listUpcoming();
    });

class MaintenanceAdminNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> createWindow({
    required String title,
    required String message,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .createWindow(
            title: title,
            message: message,
            startsAt: startsAt,
            endsAt: endsAt,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(upcomingMaintenanceWindowsProvider);
    }
  }

  Future<void> deleteWindow(String id) async {
    try {
      await ref.read(maintenanceRepositoryProvider).deleteWindow(id);
    } finally {
      ref.invalidate(upcomingMaintenanceWindowsProvider);
    }
  }
}

final maintenanceAdminNotifierProvider =
    AsyncNotifierProvider<MaintenanceAdminNotifier, void>(
      MaintenanceAdminNotifier.new,
    );
