import '../../../../../core/models/maintenance_window_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  static const _table = 'maintenance_windows';

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

  @override
  Future<void> createWindow({
    required String title,
    required String message,
    required DateTime startsAt,
    required DateTime endsAt,
    bool affectsAll = true,
    List<String>? affectedSalonIds,
  }) async {
    final userId = SupabaseService.auth.currentUser?.id;
    await SupabaseService.from(_table).insert({
      'title': title,
      'message': message,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'affects_all': affectsAll,
      'affected_salon_ids': affectedSalonIds,
      'created_by': userId,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> listUpcoming() async {
    final rows = await SupabaseService.from(_table)
        .select()
        .gte('ends_at', DateTime.now().toIso8601String())
        .order('starts_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> deleteWindow(String id) async {
    await SupabaseService.from(_table).delete().eq('id', id);
  }
}
