import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';

abstract class FeatureFlagRepository {
  Future<List<FeatureFlagModel>> getFlags();
  Future<bool> evaluateFlag(String key);
  Future<List<SalonFeatureOverrideModel>> getOverrides(String salonId);
  Future<void> setOverride({
    required String salonId,
    required String flagKey,
    required bool isEnabled,
  });
  Future<void> removeOverride({
    required String salonId,
    required String flagKey,
  });
}
