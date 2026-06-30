import 'dart:ui';

/// Langues supportées par KYNZA.
/// Ajouter une langue = 1 entrée ici + 1 fichier .arb. Rien d'autre à modifier.
enum AppLanguage {
  french(
    code: 'fr',
    countryCode: null,
    nativeName: 'Français',
    englishName: 'French',
    flagEmoji: '🇫🇷',
    isRtl: false,
  ),
  english(
    code: 'en',
    countryCode: null,
    nativeName: 'English',
    englishName: 'English',
    flagEmoji: '🇬🇧',
    isRtl: false,
  );

  const AppLanguage({
    required this.code,
    required this.countryCode,
    required this.nativeName,
    required this.englishName,
    required this.flagEmoji,
    required this.isRtl,
  });

  final String code;
  final String? countryCode;
  final String nativeName;
  final String englishName;
  final String flagEmoji;
  final bool isRtl;

  Locale get locale => Locale(code, countryCode);

  /// Fallback absolu — jamais modifier sans validation produit.
  static const AppLanguage fallback = AppLanguage.french;

  /// Résout un Locale système vers la langue KYNZA la plus proche.
  static AppLanguage fromLocale(Locale locale) {
    for (final lang in AppLanguage.values) {
      if (lang.code == locale.languageCode) return lang;
    }
    return fallback;
  }

  static AppLanguage? fromCode(String code) {
    for (final lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return null;
  }

  static AppLanguage fromCodeOrFallback(String code) =>
      fromCode(code) ?? fallback;
}
