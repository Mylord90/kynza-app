import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/features/maps/data/salon_location_cache.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_salon_location_test');
    Hive.init(tempDir.path);
    await Hive.openBox(SalonLocationCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(SalonLocationCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('SalonLocationCache', () {
    test('returns null for a salon that was never cached', () {
      expect(SalonLocationCache.get('unknown-salon'), isNull);
    });

    test('round-trips a stored coordinate pair', () async {
      await SalonLocationCache.set('salon-1', latitude: -3.376, longitude: 29.359);

      final cached = SalonLocationCache.get('salon-1');

      expect(cached, isNotNull);
      expect(cached!.latitude, -3.376);
      expect(cached.longitude, 29.359);
    });

    test('clear() removes every cached entry', () async {
      await SalonLocationCache.set('salon-1', latitude: 1, longitude: 2);
      await SalonLocationCache.clear();

      expect(SalonLocationCache.get('salon-1'), isNull);
    });
  });
}
