import '../../../../../core/models/maintenance_window_model.dart';

abstract class MaintenanceRepository {
  Future<MaintenanceWindowModel?> checkMaintenance();
}