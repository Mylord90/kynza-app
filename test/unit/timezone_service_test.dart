import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/services/timezone_service.dart';

void main() {
  setUpAll(TimeZoneService.init);

  group('TimeZoneService', () {
    test(
      'toUtc converts a Bujumbura wall-clock time to the correct UTC instant',
      () {
        // Africa/Bujumbura is UTC+2 year-round (no DST) — 08:00 local is
        // 06:00 UTC, regardless of the device's own timezone.
        final utc = TimeZoneService.toUtc(DateTime(2026, 7, 1, 8, 0));
        expect(utc.toUtc().hour, 6);
        expect(utc.toUtc().day, 1);
      },
    );

    test(
      'toLocal converts a UTC instant back to Bujumbura wall-clock time',
      () {
        final local = TimeZoneService.toLocal(DateTime.utc(2026, 7, 1, 6, 0));
        expect(local.hour, 8);
        expect(local.day, 1);
      },
    );

    test('toUtc/toLocal round-trip preserves the original wall-clock time', () {
      final original = DateTime(2026, 7, 1, 14, 30);
      final roundTripped = TimeZoneService.toLocal(
        TimeZoneService.toUtc(original),
      );
      expect(roundTripped.hour, original.hour);
      expect(roundTripped.minute, original.minute);
      expect(roundTripped.day, original.day);
    });

    test('nowLocal represents the same instant as the system clock', () {
      final systemNow = DateTime.now();
      final bujumburaNow = TimeZoneService.nowLocal();
      // Same absolute instant ("now" is now everywhere) — only the
      // wall-clock fields (hour/day) would differ if printed.
      expect(bujumburaNow.difference(systemNow).inSeconds.abs() < 5, isTrue);
    });
  });
}
