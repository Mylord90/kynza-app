import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/audit_business_repository_impl.dart';
import '../../domain/repositories/audit_business_repository.dart';

final auditBusinessRepositoryProvider = Provider<AuditBusinessRepository>(
  (ref) => AuditBusinessRepositoryImpl(),
);

final auditSecurityTrailProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(auditBusinessRepositoryProvider).getSecurityTrail(),
);

final auditRgpdTrailProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(auditBusinessRepositoryProvider).getRgpdTrail(),
);

final auditFraudProxipayProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(auditBusinessRepositoryProvider).getFraudProxipay(),
);

// Track B — no screen watches these in this pass; exist so the eventual
// report generation is a UI task, not a data-modeling task.
final auditFinancialAccountingProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) => ref.read(auditBusinessRepositoryProvider).getFinancialAccounting(),
    );
final auditUserBehaviorProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(auditBusinessRepositoryProvider).getUserBehavior(),
);
final auditSalonPerformanceProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) => ref.read(auditBusinessRepositoryProvider).getSalonPerformance(),
    );
final auditCommissionAccuracyProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) => ref.read(auditBusinessRepositoryProvider).getCommissionAccuracy(),
    );
final auditAutomationExecutionProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) => ref.read(auditBusinessRepositoryProvider).getAutomationExecution(),
    );
