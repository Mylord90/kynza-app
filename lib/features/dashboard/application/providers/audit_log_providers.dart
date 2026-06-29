import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../domain/repositories/audit_log_repository.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => AuditLogRepositoryImpl(),
);

final auditLogCategoryProvider = StateProvider<String?>((ref) => null);
final auditLogLimitProvider = StateProvider<int>((ref) => 20);

final auditLogsProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, String>((ref, salonId) {
      final category = ref.watch(auditLogCategoryProvider);
      final limit = ref.watch(auditLogLimitProvider);
      return ref
          .read(auditLogRepositoryProvider)
          .getLogs(salonId, category: category, limit: limit);
    });
