import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/remote_config_entry_model.dart';
import 'package:kynza/features/evolution/remote_config/data/remote_config_cache.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_remote_config_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox(RemoteConfigCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(RemoteConfigCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('RemoteConfigCache', () {
    test('returns null when nothing was ever cached', () {
      expect(RemoteConfigCache.get(), isNull);
      expect(RemoteConfigCache.getValue('anything'), isNull);
    });

    test('round-trips a stored entry list and resolves a single value', () async {
      final entries = [
        RemoteConfigEntryModel(
          id: 'e1',
          key: 'default_commission_rate_percent',
          category: 'commissions',
          valueJson: 10,
          valueType: 'number',
          updatedAt: DateTime(2026, 7, 4),
          createdAt: DateTime(2026, 7, 4),
        ),
      ];

      await RemoteConfigCache.set(entries);

      final cached = RemoteConfigCache.get();
      expect(cached, isNotNull);
      expect(cached!.single.key, 'default_commission_rate_percent');
      expect(
        RemoteConfigCache.getValue('default_commission_rate_percent'),
        10,
      );
      expect(RemoteConfigCache.getValue('unknown_key'), isNull);
    });
  });
}
