import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audit/audit_logger.dart';
import '../../../../core/models/permission_definition_model.dart';
import '../../../../core/models/permission_group_model.dart';
import '../../data/repositories/permission_repository_impl.dart';
import '../../domain/repositories/permission_repository.dart';

final permissionRepositoryProvider = Provider<PermissionRepository>(
  (ref) => PermissionRepositoryImpl(),
);

final permissionCatalogProvider =
    FutureProvider<List<PermissionDefinitionModel>>(
      (ref) => ref.read(permissionRepositoryProvider).getCatalog(),
    );

final permissionGroupsProvider = FutureProvider.autoDispose
    .family<List<PermissionGroupModel>, String>(
      (ref, salonId) =>
          ref.read(permissionRepositoryProvider).getGroups(salonId),
    );

final groupPermissionIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>(
      (ref, groupId) =>
          ref.read(permissionRepositoryProvider).getGroupPermissionIds(groupId),
    );

final groupMemberUserIdsProvider = FutureProvider.autoDispose
    .family<List<String>, String>(
      (ref, groupId) =>
          ref.read(permissionRepositoryProvider).getGroupMemberUserIds(groupId),
    );

final permissionGroupNotifierProvider =
    AsyncNotifierProvider<PermissionGroupNotifier, void>(
      PermissionGroupNotifier.new,
    );

class PermissionGroupNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<PermissionGroupModel> createGroup({
    required String salonId,
    required String name,
    String? description,
    required String baseRole,
  }) async {
    final group = await ref
        .read(permissionRepositoryProvider)
        .createGroup(
          salonId: salonId,
          name: name,
          description: description,
          baseRole: baseRole,
        );
    ref.invalidate(permissionGroupsProvider(salonId));
    AuditLogger.permissionGroupCreated(salonId, group.id, group.name);
    return group;
  }

  Future<void> deleteGroup({
    required String salonId,
    required String groupId,
    required String groupName,
  }) async {
    await ref.read(permissionRepositoryProvider).deleteGroup(groupId);
    ref.invalidate(permissionGroupsProvider(salonId));
    AuditLogger.permissionGroupDeleted(salonId, groupId, groupName);
  }

  Future<void> setGroupPermission({
    required String salonId,
    required String groupId,
    required String permissionId,
    required bool granted,
  }) async {
    await ref
        .read(permissionRepositoryProvider)
        .setGroupPermission(
          groupId: groupId,
          permissionId: permissionId,
          granted: granted,
        );
    ref.invalidate(groupPermissionIdsProvider(groupId));
    AuditLogger.permissionGroupPermissionChanged(
      salonId,
      groupId,
      permissionId,
      granted,
    );
  }

  Future<void> addMember({
    required String salonId,
    required String groupId,
    required String userId,
    required String grantedBy,
  }) async {
    await ref
        .read(permissionRepositoryProvider)
        .addGroupMember(
          salonId: salonId,
          groupId: groupId,
          userId: userId,
          grantedBy: grantedBy,
        );
    ref.invalidate(groupMemberUserIdsProvider(groupId));
    AuditLogger.permissionGroupMemberAdded(salonId, groupId, userId);
  }

  Future<void> removeMember({
    required String salonId,
    required String groupId,
    required String userId,
  }) async {
    await ref
        .read(permissionRepositoryProvider)
        .removeGroupMember(groupId: groupId, userId: userId);
    ref.invalidate(groupMemberUserIdsProvider(groupId));
    AuditLogger.permissionGroupMemberRemoved(salonId, groupId, userId);
  }
}
