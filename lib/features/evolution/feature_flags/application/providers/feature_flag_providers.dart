import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/audit/audit_logger.dart';
import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/role_feature_override_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../../../../core/models/user_feature_override_model.dart';
import '../../data/feature_flag_cache.dart';
import '../../data/repositories/feature_flag_repository_impl.dart';
import '../../domain/repositories/feature_flag_repository.dart';

final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>(
  (ref) => FeatureFlagRepositoryImpl(),
);

final featureFlagsProvider = FutureProvider<List<FeatureFlagModel>>((ref) {
  return ref.read(featureFlagRepositoryProvider).getFlags();
});

/// Realtime-subscribed flag catalog: a flag flipped in Supabase reaches every
/// connected app instance through this stream without a restart. Each
/// snapshot is mirrored into [FeatureFlagCache] so [featureFlagsOfflineProvider]
/// can serve the last-known list while offline or before the first event
/// arrives.
final featureFlagsRealtimeProvider = StreamProvider<List<FeatureFlagModel>>((
  ref,
) {
  final stream = ref.watch(featureFlagRepositoryProvider).watchFlags();
  return stream.map((flags) {
    FeatureFlagCache.set(flags);
    return flags;
  });
});

/// Offline-safe read: the current Realtime value if one has arrived yet,
/// otherwise the last-cached snapshot, otherwise an empty list (never a
/// blank error — consistent with this app's 5-UI-states offline convention).
final featureFlagsOfflineProvider = Provider<List<FeatureFlagModel>>((ref) {
  final live = ref.watch(featureFlagsRealtimeProvider);
  return live.when(
    data: (flags) => flags,
    loading: () => FeatureFlagCache.get() ?? const [],
    error: (_, __) => FeatureFlagCache.get() ?? const [],
  );
});

final salonFeatureOverridesProvider =
    FutureProvider.family<List<SalonFeatureOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(featureFlagRepositoryProvider).getOverrides(salonId),
    );

final roleFeatureOverridesProvider =
    FutureProvider.family<List<RoleFeatureOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(featureFlagRepositoryProvider).getRoleOverrides(salonId),
    );

final userFeatureOverridesProvider =
    FutureProvider.family<List<UserFeatureOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(featureFlagRepositoryProvider).getUserOverrides(salonId),
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
    await AuditLogger.featureFlagOverrideSet(
      salonId,
      flagKey,
      'salon',
      salonId,
      isEnabled,
    );
    ref.invalidate(salonFeatureOverridesProvider(salonId));
  }

  Future<void> removeOverride({
    required String salonId,
    required String flagKey,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .removeOverride(salonId: salonId, flagKey: flagKey);
    await AuditLogger.featureFlagOverrideRemoved(
      salonId,
      flagKey,
      'salon',
      salonId,
    );
    ref.invalidate(salonFeatureOverridesProvider(salonId));
  }

  Future<void> setRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .setRoleOverride(
          salonId: salonId,
          role: role,
          flagKey: flagKey,
          isEnabled: isEnabled,
        );
    await AuditLogger.featureFlagOverrideSet(
      salonId,
      flagKey,
      'role',
      role,
      isEnabled,
    );
    ref.invalidate(roleFeatureOverridesProvider(salonId));
  }

  Future<void> removeRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .removeRoleOverride(salonId: salonId, role: role, flagKey: flagKey);
    await AuditLogger.featureFlagOverrideRemoved(
      salonId,
      flagKey,
      'role',
      role,
    );
    ref.invalidate(roleFeatureOverridesProvider(salonId));
  }

  Future<void> setUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
    required bool isEnabled,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .setUserOverride(
          salonId: salonId,
          userId: userId,
          flagKey: flagKey,
          isEnabled: isEnabled,
        );
    await AuditLogger.featureFlagOverrideSet(
      salonId,
      flagKey,
      'user',
      userId,
      isEnabled,
    );
    ref.invalidate(userFeatureOverridesProvider(salonId));
  }

  Future<void> removeUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
  }) async {
    await ref
        .read(featureFlagRepositoryProvider)
        .removeUserOverride(salonId: salonId, userId: userId, flagKey: flagKey);
    await AuditLogger.featureFlagOverrideRemoved(
      salonId,
      flagKey,
      'user',
      userId,
    );
    ref.invalidate(userFeatureOverridesProvider(salonId));
  }
}

final featureFlagNotifierProvider =
    AsyncNotifierProvider<FeatureFlagNotifier, void>(FeatureFlagNotifier.new);
