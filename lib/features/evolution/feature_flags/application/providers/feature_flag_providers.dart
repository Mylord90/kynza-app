import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../data/repositories/feature_flag_repository_impl.dart';
import '../../domain/repositories/feature_flag_repository.dart';

final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>(
  (ref) => FeatureFlagRepositoryImpl(),
);

final featureFlagsProvider = FutureProvider<List<FeatureFlagModel>>((ref) {
  return ref.read(featureFlagRepositoryProvider).getFlags();
});

final salonFeatureOverridesProvider =
    FutureProvider.family<List<SalonFeatureOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(featureFlagRepositoryProvider).getOverrides(salonId),
    );

/// `evaluateFlag(key)` was wired into the repository when this system was
/// first built but never actually used to gate anything anywhere in the
/// app (confirmed: zero call sites besides the repository itself) — this
/// is the first reactive provider wrapping it, added for the Google Maps
/// scaffold (Phase 7 of the Enterprise Hardening pass) to gate on.
final featureFlagEvaluationProvider = FutureProvider.family<bool, String>(
  (ref, key) => ref.read(featureFlagRepositoryProvider).evaluateFlag(key),
);

class FeatureFlagNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setOverride({
    required String salonId,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .setOverride(salonId: salonId, flagKey: flagKey, isEnabled: isEnabled);
    ref.invalidate(salonFeatureOverridesProvider(salonId));
  }

  Future<void> removeOverride({
    required String salonId,
    required String flagKey,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .removeOverride(salonId: salonId, flagKey: flagKey);
    ref.invalidate(salonFeatureOverridesProvider(salonId));
  }
}

final featureFlagNotifierProvider =
    AsyncNotifierProvider<FeatureFlagNotifier, void>(FeatureFlagNotifier.new);
