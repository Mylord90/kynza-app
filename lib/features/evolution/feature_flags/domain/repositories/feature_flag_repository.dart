import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/role_feature_override_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../../../../core/models/user_feature_override_model.dart';

abstract class FeatureFlagRepository {
  Future<List<FeatureFlagModel>> getFlags();

  /// Realtime-subscribed flag catalog — emits a new list every time any row
  /// in `feature_flags` changes, so a flag flip reaches a running app
  /// instance without a restart.
  Stream<List<FeatureFlagModel>> watchFlags();

  Future<bool> evaluateFlag(String key);

  Future<List<SalonFeatureOverrideModel>> getOverrides(String salonId);
  Future<void> setOverride({
    required String salonId,
    required String flagKey,
    required bool isEnabled,
  });
  Future<void> removeOverride({required String salonId, required String flagKey});

  Future<List<RoleFeatureOverrideModel>> getRoleOverrides(String salonId);
  Future<void> setRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
    required bool isEnabled,
  });
  Future<void> removeRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
  });

  Future<List<UserFeatureOverrideModel>> getUserOverrides(String salonId);
  Future<void> setUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
    required bool isEnabled,
  });
  Future<void> removeUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
  });
}
