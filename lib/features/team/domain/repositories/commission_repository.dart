import '../../../../core/models/staff_commission_model.dart';

abstract class CommissionRepository {
  Future<List<StaffCommissionModel>> getStaffCommissions(
    String staffId,
    DateTime month,
  );
  Future<List<StaffCommissionModel>> getSalonCommissions(
    String salonId,
    DateTime month,
  );
  Future<void> markPaid(List<String> commissionIds);
  Future<CommissionSummary> getCommissionSummary(
    String salonId,
    DateTime month,
  );
  Future<void> updateCommissionRate(String staffId, String type, num value);
}
