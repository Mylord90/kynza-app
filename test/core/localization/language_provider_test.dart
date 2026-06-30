import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/localization/models/language_enum.dart';

void main() {
  group('languageProvider', () {
    test('AppLanguage fromCode returns null for unknown code', () {
      expect(AppLanguage.fromCode('zz'), isNull);
    });

    test('AppLanguage fromCode returns the matching language', () {
      expect(AppLanguage.fromCode('fr'), AppLanguage.french);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
    });

    test('AppLanguage fromCodeOrFallback uses french as fallback', () {
      expect(AppLanguage.fromCodeOrFallback('xx'), AppLanguage.french);
    });

    test('AppLanguage values covers all supported languages', () {
      final codes = AppLanguage.values.map((l) => l.code).toSet();
      expect(codes, containsAll(['fr', 'en']));
    });

    test('AppLanguage.isRtl is false for fr and en', () {
      expect(AppLanguage.french.isRtl, isFalse);
      expect(AppLanguage.english.isRtl, isFalse);
    });
  });
}
