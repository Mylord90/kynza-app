import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/role_feature_override_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../../../../core/models/user_feature_override_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/feature_flag_repository.dart';

class FeatureFlagRepositoryImpl implements FeatureFlagRepository {
  @override
  Future<List<FeatureFlagModel>> getFlags() async {
    final rows = await SupabaseService.from(
      'feature_flags',
    ).select().order('name');
    return rows.map((r) => FeatureFlagModel.fromJson(r)).toList();
  }

  @override
  Stream<List<FeatureFlagModel>> watchFlags() {
    return SupabaseService.client
        .from('feature_flags')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(FeatureFlagModel.fromJson).toList());
  }

  @override
  Future<bool> evaluateFlag(String key) async {
    final result = await SupabaseService.client.rpc(
      'evaluate_feature_flag',
      params: {'p_key': key},
    );
    return result as bool? ?? false;
  }

  @override
  Future<List<SalonFeatureOverrideModel>> getOverrides(String salonId) async {
    final rows = await SupabaseService.from(
      'salon_feature_overrides',
    ).select().eq('salon_id', salonId).order('flag_key');
    return rows.map((r) => SalonFeatureOverrideModel.fromJson(r)).toList();
  }

  @override
  Future<void> setOverride({
    required String salonId,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await SupabaseService.from('salon_feature_overrides').upsert({
      'salon_id': salonId,
      'flag_key': flagKey,
      'is_enabled': isEnabled,
    }, onConflict: 'salon_id,flag_key');
  }

  @override
  Future<void> removeOverride({
    required String salonId,
    required String flagKey,
  }) async {
    await SupabaseService.from(
      'salon_feature_overrides',
    ).delete().eq('salon_id', salonId).eq('flag_key', flagKey);
  }

  @override
  Future<List<RoleFeatureOverrideModel>> getRoleOverrides(
    String salonId,
  ) async {
    final rows = await SupabaseService.from(
      'role_feature_overrides',
    ).select().eq('salon_id', salonId).order('flag_key');
    return rows.map((r) => RoleFeatureOverrideModel.fromJson(r)).toList();
  }

  @override
  Future<void> setRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await SupabaseService.from('role_feature_overrides').upsert({
      'salon_id': salonId,
      'role': role,
      'flag_key': flagKey,
      'is_enabled': isEnabled,
    }, onConflict: 'salon_id,role,flag_key');
  }

  @override
  Future<void> removeRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
  }) async {
    await SupabaseService.from('role_feature_overrides')
        .delete()
        .eq('salon_id', salonId)
        .eq('role', role)
        .eq('flag_key', flagKey);
  }

  @override
  Future<List<UserFeatureOverrideModel>> getUserOverrides(
    String salonId,
  ) async {
    final rows = await SupabaseService.from(
      'user_feature_overrides',
    ).select().eq('salon_id', salonId).order('flag_key');
    return rows.map((r) => UserFeatureOverrideModel.fromJson(r)).toList();
  }

  @override
  Future<void> setUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await SupabaseService.from('user_feature_overrides').upsert({
      'salon_id': salonId,
      'user_id': userId,
      'flag_key': flagKey,
      'is_enabled': isEnabled,
    }, onConflict: 'salon_id,user_id,flag_key');
  }

  @override
  Future<void> removeUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
  }) async {
    await SupabaseService.from('user_feature_overrides')
        .delete()
        .eq('salon_id', salonId)
        .eq('user_id', userId)
        .eq('flag_key', flagKey);
  }
}
