import '../../../../core/models/permission_definition_model.dart';
import '../../../../core/models/permission_group_model.dart';

abstract class PermissionRepository {
  Future<List<PermissionDefinitionModel>> getCatalog();

  Future<List<PermissionGroupModel>> getGroups(String salonId);

  Future<PermissionGroupModel> createGroup({
    required String salonId,
    required String name,
    String? description,
    required String baseRole,
  });

  Future<void> deleteGroup(String groupId);

  /// Permission ids granted (granted = true) for this group.
  Future<Set<String>> getGroupPermissionIds(String groupId);

  Future<void> setGroupPermission({
    required String groupId,
    required String permissionId,
    required bool granted,
  });

  /// user_id of every active (non-expired, non-deleted) member.
  Future<List<String>> getGroupMemberUserIds(String groupId);

  Future<void> addGroupMember({
    required String salonId,
    required String groupId,
    required String userId,
    required String grantedBy,
  });

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  });
}
