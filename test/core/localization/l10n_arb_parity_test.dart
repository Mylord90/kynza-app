import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB parity', () {
    test('app_fr.arb and app_en.arb have identical key sets', () {
      final frRaw = File('lib/l10n/app_fr.arb').readAsStringSync();
      final enRaw = File('lib/l10n/app_en.arb').readAsStringSync();

      final frKeys = _extractKeys(frRaw);
      final enKeys = _extractKeys(enRaw);

      final missingInEn = frKeys.difference(enKeys);
      final missingInFr = enKeys.difference(frKeys);

      expect(
        missingInEn,
        isEmpty,
        reason:
            'Keys present in app_fr.arb but missing in app_en.arb:\n'
            '${missingInEn.toList()..sort()}',
      );
      expect(
        missingInFr,
        isEmpty,
        reason:
            'Keys present in app_en.arb but missing in app_fr.arb:\n'
            '${missingInFr.toList()..sort()}',
      );
    });

    test('neither ARB file is empty', () {
      final frKeys = _extractKeys(
        File('lib/l10n/app_fr.arb').readAsStringSync(),
      );
      final enKeys = _extractKeys(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      );
      expect(frKeys.length, greaterThan(100));
      expect(enKeys.length, greaterThan(100));
    });

    test('all keys in app_fr.arb have non-empty French values', () {
      final raw = File('lib/l10n/app_fr.arb').readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        if (entry.key.startsWith('@') || entry.key == '@@locale') continue;
        // Only check string values (not ICU plurals encoded as maps)
        if (entry.value is String) {
          expect(
            (entry.value as String).trim(),
            isNotEmpty,
            reason: 'French value for key "${entry.key}" is empty',
          );
        }
      }
    });

    test('all keys in app_en.arb have non-empty English values', () {
      final raw = File('lib/l10n/app_en.arb').readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        if (entry.key.startsWith('@') || entry.key == '@@locale') continue;
        if (entry.value is String) {
          expect(
            (entry.value as String).trim(),
            isNotEmpty,
            reason: 'English value for key "${entry.key}" is empty',
          );
        }
      }
    });
  });
}

Set<String> _extractKeys(String arbContent) {
  final map = jsonDecode(arbContent) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet();
}
