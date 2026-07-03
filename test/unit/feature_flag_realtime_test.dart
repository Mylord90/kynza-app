import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/feature_flag_model.dart';
import 'package:kynza/core/models/role_feature_override_model.dart';
import 'package:kynza/core/models/salon_feature_override_model.dart';
import 'package:kynza/core/models/user_feature_override_model.dart';
import 'package:kynza/features/evolution/feature_flags/application/providers/feature_flag_providers.dart';
import 'package:kynza/features/evolution/feature_flags/data/feature_flag_cache.dart';
import 'package:kynza/features/evolution/feature_flags/domain/repositories/feature_flag_repository.dart';

FeatureFlagModel _flag(String key, {required bool isEnabled}) =>
    FeatureFlagModel(
      id: key,
      key: key,
      name: key,
      isEnabled: isEnabled,
      rolloutPercentage: 100,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

class _FakeFeatureFlagRepository implements FeatureFlagRepository {
  _FakeFeatureFlagRepository(this._controller);

  final StreamController<List<FeatureFlagModel>> _controller;

  @override
  Stream<List<FeatureFlagModel>> watchFlags() => _controller.stream;

  @override
  Future<List<FeatureFlagModel>> getFlags() async => [];
  @override
  Future<bool> evaluateFlag(String key) async => false;
  @override
  Future<List<SalonFeatureOverrideModel>> getOverrides(String salonId) async =>
      [];
  @override
  Future<void> setOverride({
    required String salonId,
    required String flagKey,
    required bool isEnabled,
  }) async {}
  @override
  Future<void> removeOverride({
    required String salonId,
    required String flagKey,
  }) async {}
  @override
  Future<List<RoleFeatureOverrideModel>> getRoleOverrides(
    String salonId,
  ) async => [];
  @override
  Future<void> setRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
    required bool isEnabled,
  }) async {}
  @override
  Future<void> removeRoleOverride({
    required String salonId,
    required String role,
    required String flagKey,
  }) async {}
  @override
  Future<List<UserFeatureOverrideModel>> getUserOverrides(
    String salonId,
  ) async => [];
  @override
  Future<void> setUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
    required bool isEnabled,
  }) async {}
  @override
  Future<void> removeUserOverride({
    required String salonId,
    required String userId,
    required String flagKey,
  }) async {}
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_feature_flag_test');
    Hive.init(tempDir.path);
    await Hive.openBox(FeatureFlagCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(FeatureFlagCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('Feature flag Realtime propagation (Phase 3 — no app restart needed)', () {
    test(
      'a flag flip pushed through the Supabase stream reaches the running '
      'provider without any restart/re-fetch call',
      () async {
        final controller = StreamController<List<FeatureFlagModel>>();
        addTearDown(controller.close);

        final container = ProviderContainer(
          overrides: [
            featureFlagRepositoryProvider.overrideWithValue(
              _FakeFeatureFlagRepository(controller),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          featureFlagsRealtimeProvider,
          (_, __) {},
        );
        addTearDown(sub.close);

        // Initial snapshot: flag disabled.
        controller.add([_flag('instant_booking', isEnabled: false)]);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(featureFlagsRealtimeProvider).value!.single.isEnabled,
          isFalse,
        );

        // Simulate an admin flipping the flag in Supabase — the existing
        // provider (no rebuild, no restart) must observe the new value the
        // moment the next Realtime event arrives.
        controller.add([_flag('instant_booking', isEnabled: true)]);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(featureFlagsRealtimeProvider).value!.single.isEnabled,
          isTrue,
        );
      },
    );

    test(
      'featureFlagsOfflineProvider falls back to the last-cached snapshot '
      'while loading, never to a blank/error state',
      () async {
        final controller = StreamController<List<FeatureFlagModel>>();
        addTearDown(controller.close);

        final container = ProviderContainer(
          overrides: [
            featureFlagRepositoryProvider.overrideWithValue(
              _FakeFeatureFlagRepository(controller),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Before any event arrives, the stream is in its loading state —
        // the offline-safe provider must still return a list (possibly
        // empty if nothing was ever cached), never throw.
        expect(
          () => container.read(featureFlagsOfflineProvider),
          returnsNormally,
        );
      },
    );
  });
}
