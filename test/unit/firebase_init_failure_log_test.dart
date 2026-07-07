import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/services/crash_reporting_service.dart';
import 'package:kynza/core/services/firebase_init_failure_log.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'kynza_firebase_init_failure_test',
    );
    Hive.init(tempDir.path);
    await Hive.openBox(FirebaseInitFailureLog.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(FirebaseInitFailureLog.boxName);
    await tempDir.delete(recursive: true);
  });

  group('FirebaseInitFailureLog', () {
    test('peek() returns null when nothing was recorded', () {
      expect(FirebaseInitFailureLog.peek(), isNull);
    });

    test('record() then peek() round-trips the error and a timestamp', () async {
      await FirebaseInitFailureLog.record(Exception('no default app'));

      final entry = FirebaseInitFailureLog.peek();

      expect(entry, isNotNull);
      expect(entry!['error'], contains('no default app'));
      expect(entry['timestamp'], isNotNull);
    });

    test('clear() removes the recorded entry', () async {
      await FirebaseInitFailureLog.record(Exception('boom'));
      await FirebaseInitFailureLog.clear();

      expect(FirebaseInitFailureLog.peek(), isNull);
    });
  });

  group('CrashReportingService.reportPendingInitFailure', () {
    test('does nothing when no failure was recorded', () async {
      var called = false;

      await CrashReportingService.reportPendingInitFailure(
        recordError: (error, {required reason, required fatal}) =>
            called = true,
      );

      expect(called, isFalse);
    });

    test(
      'reports the pending failure as a non-fatal error, then clears it',
      () async {
        await FirebaseInitFailureLog.record(
          Exception('missing google-services.json'),
        );

        Object? reportedError;
        String? reportedReason;
        bool? reportedFatal;
        await CrashReportingService.reportPendingInitFailure(
          recordError: (error, {required reason, required fatal}) {
            reportedError = error;
            reportedReason = reason;
            reportedFatal = fatal;
          },
        );

        expect(
          reportedError.toString(),
          contains('missing google-services.json'),
        );
        expect(reportedReason, 'firebase_init_failure_catch_up');
        expect(reportedFatal, isFalse);
        expect(
          FirebaseInitFailureLog.peek(),
          isNull,
          reason: 'must clear the entry after reporting it',
        );
      },
    );
  });
}
