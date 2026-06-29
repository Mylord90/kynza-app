import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/audit_log_repository.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  @override
  Future<List<AuditLogModel>> getLogs(
    String salonId, {
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      var query = SupabaseService.from(
        'activity_logs',
      ).select('*, user:user_id(full_name)').eq('salon_id', salonId);
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final logs = rows.map(AuditLogModel.fromSupabase).toList();
      if (category == null) return logs;
      return logs
          .where((l) => auditLogCategoryFor(l.typeAction) == category)
          .toList();
    } catch (_) {
      throw const AppException("Impossible de charger le journal d'activité.");
    }
  }
}
