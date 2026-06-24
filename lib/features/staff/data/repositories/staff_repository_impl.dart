import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  static const _table = 'staff_profiles';
  static const _servicesTable = 'staff_services';

  @override
  Future<List<StaffProfileModel>> getStaff(String salonId) async {
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('salon_id', salonId)
        .isFilter('deleted_at', null)
        .order('created_at');
    return rows.map(StaffProfileModel.fromSupabase).toList();
  }

  @override
  Future<StaffProfileModel> inviteStaff({
    required String salonId,
    required String displayName,
    required String phone,
    required String role,
    required String callerRole,
  }) async {
    if (role == 'manager' && callerRole != 'owner') {
      throw const AppException(
        "Seul le propriétaire peut désigner un manager.",
      );
    }
    try {
      final currentUserId = SupabaseService.auth.currentUser?.id;
      final row = await SupabaseService.from(_table)
          .insert({
            'salon_id': salonId,
            'display_name': displayName,
            'phone': phone,
            'role': role,
            'invited_by': currentUserId,
          })
          .select()
          .single();
      return StaffProfileModel.fromSupabase(row);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException("Impossible d'envoyer l'invitation.");
    }
  }

  @override
  Future<StaffProfileModel> updateStaff(StaffProfileModel staff) async {
    try {
      final row = await SupabaseService.from(_table)
          .update({
            'display_name': staff.displayName,
            'bio': staff.bio,
            'phone': staff.phone,
            'specialties': staff.specialties,
            'avatar_url': staff.avatarUrl,
          })
          .eq('id', staff.id!)
          .select()
          .single();
      return StaffProfileModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour ce membre.');
    }
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'is_active': isActive}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour ce membre.');
    }
  }

  @override
  Future<void> removeStaff(String id) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException(
        'Impossible de retirer ce membre (RDV futurs en attente ?).',
      );
    }
  }

  @override
  Future<void> assignService(
    String staffId,
    String serviceId,
    String salonId,
  ) async {
    try {
      await SupabaseService.from(_servicesTable).upsert({
        'staff_id': staffId,
        'service_id': serviceId,
        'salon_id': salonId,
      }, onConflict: 'staff_id,service_id');
    } catch (_) {
      throw const AppException("Impossible d'assigner ce service.");
    }
  }

  @override
  Future<void> removeService(String staffId, String serviceId) async {
    try {
      await SupabaseService.from(
        _servicesTable,
      ).delete().eq('staff_id', staffId).eq('service_id', serviceId);
    } catch (_) {
      throw const AppException('Impossible de retirer ce service.');
    }
  }

  @override
  Future<List<String>> getAssignedServiceIds(String staffId) async {
    final rows = await SupabaseService.from(
      _servicesTable,
    ).select('service_id').eq('staff_id', staffId).isFilter('deleted_at', null);
    return rows.map((r) => r['service_id'] as String).toList();
  }
}
