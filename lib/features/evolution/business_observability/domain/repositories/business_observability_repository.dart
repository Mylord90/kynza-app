/// Track B (Backend Enterprise Completion, Phase 6) — schema/pipeline
/// access only. Deliberately no dashboard screens consume this in this
/// pass; the repository/provider layer exists so the eventual dashboard UI
/// is a UI task, not a data-modeling task, per the brief's own framing.
/// Raw rows (`Map<String, dynamic>`) for the same reason as
/// `HealthCenterRepository` — 13 different view shapes, internal/reporting
/// only, no persistence or business logic operates on these yet.
abstract class BusinessObservabilityRepository {
  Future<List<Map<String, dynamic>>> getRevenue();
  Future<List<Map<String, dynamic>>> getSalons();
  Future<List<Map<String, dynamic>>> getStaff();
  Future<List<Map<String, dynamic>>> getClients();
  Future<List<Map<String, dynamic>>> getSubscriptions();
  Future<List<Map<String, dynamic>>> getCommissions();
  Future<List<Map<String, dynamic>>> getBookings();
  Future<List<Map<String, dynamic>>> getPayments();
  Future<List<Map<String, dynamic>>> getLoyalty();
  Future<List<Map<String, dynamic>>> getReferrals();
  Future<List<Map<String, dynamic>>> getActivation();
  Future<List<Map<String, dynamic>>> getLtv();
  Future<List<Map<String, dynamic>>> getConversion();
}
