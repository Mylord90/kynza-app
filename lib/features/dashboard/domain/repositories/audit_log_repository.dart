import '../../../../core/models/audit_log_model.dart';

abstract class AuditLogRepository {
  Future<List<AuditLogModel>> getLogs(
    String salonId, {
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  });
}
