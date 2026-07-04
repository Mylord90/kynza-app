import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/audit_business_repository.dart';

class AuditBusinessRepositoryImpl implements AuditBusinessRepository {
  Future<List<Map<String, dynamic>>> _callRpc(String function) async {
    final result = await SupabaseService.client.rpc(function);
    if (result is List) {
      return result.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    }
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSecurityTrail() =>
      _callRpc('get_audit_security_trail');

  @override
  Future<List<Map<String, dynamic>>> getRgpdTrail() =>
      _callRpc('get_audit_rgpd_trail');

  @override
  Future<List<Map<String, dynamic>>> getFraudProxipay() =>
      _callRpc('get_audit_fraud_proxipay');

  @override
  Future<List<Map<String, dynamic>>> getFinancialAccounting() =>
      _callRpc('get_audit_financial_accounting');

  @override
  Future<List<Map<String, dynamic>>> getUserBehavior() =>
      _callRpc('get_audit_user_behavior');

  @override
  Future<List<Map<String, dynamic>>> getSalonPerformance() =>
      _callRpc('get_audit_salon_performance');

  @override
  Future<List<Map<String, dynamic>>> getCommissionAccuracy() =>
      _callRpc('get_audit_commission_accuracy');

  @override
  Future<List<Map<String, dynamic>>> getAutomationExecution() =>
      _callRpc('get_audit_automation_execution');
}
