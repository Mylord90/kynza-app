/// Each method returns raw rows (`Map<String, dynamic>`) rather than typed
/// Freezed models — this is an internal SYSTEM_ADMIN-only ops surface, and
/// each of the 7 underlying views has a different shape; a typed model per
/// view would add ceremony without real benefit here (no persistence, no
/// business logic operates on these beyond display).
abstract class HealthCenterRepository {
  Future<List<Map<String, dynamic>>> getSupabaseDashboard();
  Future<List<Map<String, dynamic>>> getStorageDashboard();
  Future<List<Map<String, dynamic>>> getNotificationDashboard();
  Future<List<Map<String, dynamic>>> getQueueDashboard();
  Future<List<Map<String, dynamic>>> getEdgeFunctionDashboard();
  Future<List<Map<String, dynamic>>> getCrashDashboard();
  Future<List<Map<String, dynamic>>> getSecurityDashboard();
}
