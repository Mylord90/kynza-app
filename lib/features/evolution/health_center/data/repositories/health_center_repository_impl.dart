import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/health_center_repository.dart';

class HealthCenterRepositoryImpl implements HealthCenterRepository {
  Future<List<Map<String, dynamic>>> _callRpc(String function) async {
    final result = await SupabaseService.client.rpc(function);
    if (result is List) {
      return result.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    }
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSupabaseDashboard() =>
      _callRpc('get_supabase_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getStorageDashboard() =>
      _callRpc('get_storage_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getNotificationDashboard() =>
      _callRpc('get_notification_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getQueueDashboard() =>
      _callRpc('get_queue_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getEdgeFunctionDashboard() =>
      _callRpc('get_edge_function_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getCrashDashboard() =>
      _callRpc('get_crash_dashboard');

  @override
  Future<List<Map<String, dynamic>>> getSecurityDashboard() =>
      _callRpc('get_security_dashboard');
}
