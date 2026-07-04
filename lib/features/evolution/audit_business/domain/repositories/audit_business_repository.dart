/// Track A of Phase 10 (Backend Enterprise Completion) — 3 genuinely new
/// audit views. Error/Performance/Sync audits deliberately reuse Phase 2's
/// Health Center pipelines rather than being re-exposed here (see
/// `docs/backend-completion/PHASE_10_AUDIT_ENGINE.md`).
abstract class AuditBusinessRepository {
  Future<List<Map<String, dynamic>>> getSecurityTrail();
  Future<List<Map<String, dynamic>>> getRgpdTrail();
  Future<List<Map<String, dynamic>>> getFraudProxipay();

  // Track B — schema-only, no report screen consumes these in this pass.
  Future<List<Map<String, dynamic>>> getFinancialAccounting();
  Future<List<Map<String, dynamic>>> getUserBehavior();
  Future<List<Map<String, dynamic>>> getSalonPerformance();
  Future<List<Map<String, dynamic>>> getCommissionAccuracy();
  Future<List<Map<String, dynamic>>> getAutomationExecution();
}
