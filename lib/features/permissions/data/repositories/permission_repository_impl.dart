import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/permission_definition_model.dart';
import '../../../../core/models/permission_group_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  @override
  Future<List<PermissionDefinitionModel>> getCatalog() async {
    try {
      final rows = await SupabaseService.from(
        'permission_definitions',
      ).select().order('feature').order('action');
      return rows.map(PermissionDefinitionModel.fromJson).toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger le catalogue des permissions.',
      );
    }
  }

  @override
  Future<List<PermissionGroupModel>> getGroups(String salonId) async {
    try {
      final rows = await SupabaseService.from('permission_groups')
          .select()
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .order('created_at');
      return rows.map(PermissionGroupModel.fromJson).toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger les groupes de permissions.',
      );
    }
  }

  @override
  Future<PermissionGroupModel> createGroup({
    required String salonId,
    required String name,
    String? description,
    required String baseRole,
  }) async {
    try {
      final row = await SupabaseService.from('permission_groups')
          .insert({
            'salon_id': salonId,
            'name': name,
            'description': description,
            'base_role': baseRole,
          })
          .select()
          .single();
      return PermissionGroupModel.fromJson(row);
    } catch (_) {
      throw const AppException('Impossible de créer ce groupe.');
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await SupabaseService.from('permission_groups')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', groupId);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce groupe.');
    }
  }

  @override
  Future<Set<String>> getGroupPermissionIds(String groupId) async {
    try {
      final rows = await SupabaseService.from(
        'permission_group_permissions',
      ).select('permission_id').eq('group_id', groupId).eq('granted', true);
      return rows.map((r) => r['permission_id'] as String).toSet();
    } catch (_) {
      throw const AppException(
        'Impossible de charger les permissions de ce groupe.',
      );
    }
  }

  @override
  Future<void> setGroupPermission({
    required String groupId,
    required String permissionId,
    required bool granted,
  }) async {
    try {
      await SupabaseService.from('permission_group_permissions').upsert({
        'group_id': groupId,
        'permission_id': permissionId,
        'granted': granted,
      }, onConflict: 'group_id,permission_id');
    } catch (_) {
      throw const AppException('Impossible de modifier cette permission.');
    }
  }

  @override
  Future<List<String>> getGroupMemberUserIds(String groupId) async {
    try {
      final rows = await SupabaseService.from(
        'user_permission_groups',
      ).select('user_id').eq('group_id', groupId).isFilter('deleted_at', null);
      return rows.map((r) => r['user_id'] as String).toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger les membres de ce groupe.',
      );
    }
  }

  @override
  Future<void> addGroupMember({
    required String salonId,
    required String groupId,
    required String userId,
    required String grantedBy,
  }) async {
    try {
      // Re-adding a previously soft-removed member must revive the row
      // (salon_id, user_id, group_id) is UNIQUE — a plain INSERT would
      // collide with that row's still-existing primary key.
      await SupabaseService.from('user_permission_groups').upsert({
        'salon_id': salonId,
        'group_id': groupId,
        'user_id': userId,
        'granted_by': grantedBy,
        'granted_at': DateTime.now().toIso8601String(),
        'deleted_at': null,
      }, onConflict: 'salon_id,user_id,group_id');
    } catch (_) {
      throw const AppException('Impossible d\'ajouter ce membre.');
    }
  }

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await SupabaseService.from('user_permission_groups')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (_) {
      throw const AppException('Impossible de retirer ce membre.');
    }
  }
}
