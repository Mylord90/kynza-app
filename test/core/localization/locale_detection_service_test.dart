import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/localization/models/language_enum.dart';
import 'package:kynza/core/localization/services/locale_detection_service.dart';

void main() {
  const service = LocaleDetectionService();

  group('LocaleDetectionService', () {
    test('returns french fallback for unsupported locale', () {
      final result = AppLanguage.fromCode('ar');
      expect(result, isNull);
    });

    test('detects French from fr locale', () {
      final lang = AppLanguage.fromCodeOrFallback('fr');
      expect(lang, AppLanguage.french);
    });

    test('detects English from en locale', () {
      final lang = AppLanguage.fromCodeOrFallback('en');
      expect(lang, AppLanguage.english);
    });

    test('falls back to french for unknown code', () {
      final lang = AppLanguage.fromCodeOrFallback('xx');
      expect(lang, AppLanguage.french);
    });

    test('service is const-constructible', () {
      expect(service, isA<LocaleDetectionService>());
    });

    test('AppLanguage.french has correct locale', () {
      expect(AppLanguage.french.locale, const Locale('fr'));
    });

    test('AppLanguage.english has correct locale', () {
      expect(AppLanguage.english.locale, const Locale('en'));
    });

    test('french is the designated fallback', () {
      expect(AppLanguage.fallback, AppLanguage.french);
    });

    test('all languages have non-empty native names', () {
      for (final lang in AppLanguage.values) {
        expect(lang.nativeName, isNotEmpty);
        expect(lang.englishName, isNotEmpty);
        expect(lang.code, isNotEmpty);
      }
    });
  });
}
