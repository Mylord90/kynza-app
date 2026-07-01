import '../../../../../core/models/maintenance_window_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  @override
  Future<MaintenanceWindowModel?> checkMaintenance() async {
    // RPC requires auth.uid() — skip if not authenticated
    if (SupabaseService.auth.currentUser == null) return null;

    final rows =
        await SupabaseService.client.rpc('is_maintenance_active')
            as List<dynamic>;

    if (rows.isEmpty) return null;
    return MaintenanceWindowModel.fromJson(rows.first as Map<String, dynamic>);
  }
}
