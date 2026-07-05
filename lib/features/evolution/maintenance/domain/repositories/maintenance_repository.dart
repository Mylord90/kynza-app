import '../../../../../core/models/maintenance_window_model.dart';

abstract class MaintenanceRepository {
  Future<MaintenanceWindowModel?> checkMaintenance();

  /// Admin-only (RLS: `has_system_admin`). P3-11 (Master Plan Execution
  /// CP3) — the only write path onto `maintenance_windows`; previously
  /// SQL-only.
  Future<void> createWindow({
    required String title,
    required String message,
    required DateTime startsAt,
    required DateTime endsAt,
    bool affectsAll = true,
    List<String>? affectedSalonIds,
  });

  Future<List<Map<String, dynamic>>> listUpcoming();

  Future<void> deleteWindow(String id);
}
