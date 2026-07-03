import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/features/evolution/health_center/application/providers/health_center_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_health_center_test');
    Hive.init(tempDir.path);
    await Hive.openBox(MutationOutboxService.boxName);
    await Hive.openBox(MutationOutboxService.deadLetterBoxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    await tempDir.delete(recursive: true);
  });

  group('Sync Dashboard (Phase 2 — genuinely client-only, no SQL view)', () {
    test('reflects real pending/dead-letter counts from the outbox', () async {
      final outbox = MutationOutboxService();
      await outbox.enqueue(type: 'reviewCreate', payload: {'a': 1});
      await outbox.enqueue(type: 'profileUpdate', payload: {'b': 2});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final status = container.read(syncDashboardProvider);

      expect(status.pendingCount, 2);
      expect(status.deadLetterCount, 0);
    });

    test('starts at zero when nothing has ever been queued', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final status = container.read(syncDashboardProvider);

      expect(status.pendingCount, 0);
      expect(status.deadLetterCount, 0);
    });
  });
}
