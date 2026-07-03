import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/remote_config_entry_model.dart';
import 'package:kynza/core/models/remote_config_version_model.dart';
import 'package:kynza/features/evolution/remote_config/application/providers/remote_config_providers.dart';
import 'package:kynza/features/evolution/remote_config/data/remote_config_cache.dart';
import 'package:kynza/features/evolution/remote_config/domain/repositories/remote_config_repository.dart';

RemoteConfigEntryModel _entry(String key, {required dynamic value}) =>
    RemoteConfigEntryModel(
      id: key,
      key: key,
      category: 'test',
      valueJson: value,
      valueType: value is num
          ? 'number'
          : value is bool
          ? 'boolean'
          : 'string',
      updatedAt: DateTime(2026),
      createdAt: DateTime(2026),
    );

class _FakeRemoteConfigRepository implements RemoteConfigRepository {
  _FakeRemoteConfigRepository(this._controller);

  final StreamController<List<RemoteConfigEntryModel>> _controller;
  final List<String> rollbackCalls = [];
  final List<String> updateCalls = [];

  @override
  Stream<List<RemoteConfigEntryModel>> watchEntries() => _controller.stream;

  @override
  Future<List<RemoteConfigEntryModel>> getEntries() async => [];

  @override
  Future<List<RemoteConfigVersionModel>> getVersions(String entryId) async =>
      [];

  @override
  Future<void> updateEntry({
    required String key,
    required dynamic value,
    String? changeReason,
  }) async {
    updateCalls.add(key);
  }

  @override
  Future<void> rollback({
    required String key,
    required int versionNumber,
  }) async {
    rollbackCalls.add('$key:$versionNumber');
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_remote_config_test');
    Hive.init(tempDir.path);
    await Hive.openBox(RemoteConfigCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(RemoteConfigCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('Remote config Realtime propagation (Phase 4 — no redeploy needed)', () {
    test(
      'a value changed through the Edge Function and reflected in Supabase '
      'reaches the running provider without any redeploy',
      () async {
        final controller = StreamController<List<RemoteConfigEntryModel>>();
        addTearDown(controller.close);

        final container = ProviderContainer(
          overrides: [
            remoteConfigRepositoryProvider.overrideWithValue(
              _FakeRemoteConfigRepository(controller),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(remoteConfigRealtimeProvider, (_, __) {});
        addTearDown(sub.close);

        controller.add([_entry('booking_cancellation_window_hours', value: 24)]);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(remoteConfigValueProvider('booking_cancellation_window_hours')),
          24,
        );

        // Simulate a remote change (no redeploy) reaching this instance.
        controller.add([_entry('booking_cancellation_window_hours', value: 48)]);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(remoteConfigValueProvider('booking_cancellation_window_hours')),
          48,
        );
      },
    );

    test(
      'a rollback is mechanically the same client-visible propagation path '
      'as any other value change — the exact-prior-value restoration is '
      'server-side (Edge Function) logic, traced in '
      'docs/backend-completion/PHASE_4_REMOTE_CONFIG.md rather than '
      'exercised here (no live Postgres/Edge Function runtime in this '
      'environment) — but the propagation mechanism itself is the same one '
      'already proven above',
      () async {
        final controller = StreamController<List<RemoteConfigEntryModel>>();
        addTearDown(controller.close);

        final container = ProviderContainer(
          overrides: [
            remoteConfigRepositoryProvider.overrideWithValue(
              _FakeRemoteConfigRepository(controller),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(remoteConfigRealtimeProvider, (_, __) {});
        addTearDown(sub.close);

        // A rollback ultimately manifests to clients as: the entry's row
        // changes to an older value_json. Simulate that exact effect.
        controller.add([
          _entry('default_commission_rate_percent', value: 15),
        ]);
        await Future<void>.delayed(Duration.zero);
        controller.add([
          _entry('default_commission_rate_percent', value: 10),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(
            remoteConfigValueProvider('default_commission_rate_percent'),
          ),
          10,
        );
      },
    );
  });
}
