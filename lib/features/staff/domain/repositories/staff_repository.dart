import '../../../../core/models/staff_profile_model.dart';

abstract class StaffRepository {
  Future<List<StaffProfileModel>> getStaff(String salonId);
  Future<StaffProfileModel> inviteStaff({
    required String salonId,
    required String displayName,
    required String phone,
    required String role,
    required String callerRole,
  });
  Future<StaffProfileModel> updateStaff(StaffProfileModel staff);
  Future<void> toggleActive(String id, bool isActive);
  Future<void> removeStaff(String id);
  Future<void> assignService(String staffId, String serviceId, String salonId);
  Future<void> removeService(String staffId, String serviceId);
  Future<List<String>> getAssignedServiceIds(String staffId);
}
