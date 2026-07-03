import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/feature_flag_model.dart';
import 'package:kynza/features/evolution/feature_flags/data/feature_flag_cache.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_feature_flag_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox(FeatureFlagCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(FeatureFlagCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('FeatureFlagCache', () {
    test('returns null when nothing was ever cached', () {
      expect(FeatureFlagCache.get(), isNull);
    });

    test('round-trips a stored flag list', () async {
      final flags = [
        FeatureFlagModel(
          id: 'f1',
          key: 'instant_booking',
          name: 'Réservation instantanée',
          isEnabled: true,
          rolloutPercentage: 100,
          category: 'Booking',
          createdAt: DateTime(2026, 7, 4),
          updatedAt: DateTime(2026, 7, 4),
        ),
      ];

      await FeatureFlagCache.set(flags);
      final cached = FeatureFlagCache.get();

      expect(cached, isNotNull);
      expect(cached!.single.key, 'instant_booking');
      expect(cached.single.isEnabled, isTrue);
      expect(cached.single.category, 'Booking');
    });

    test('clear() removes the cached snapshot', () async {
      await FeatureFlagCache.set([
        FeatureFlagModel(
          id: 'f1',
          key: 'k',
          name: 'k',
          isEnabled: false,
          rolloutPercentage: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      await FeatureFlagCache.clear();

      expect(FeatureFlagCache.get(), isNull);
    });
  });
}
