import 'dart:ui';

import '../models/language_enum.dart';

/// Détecte la langue système sans jamais afficher de sélecteur.
/// Retourne toujours une langue valide (jamais null).
class LocaleDetectionService {
  const LocaleDetectionService();

  AppLanguage detectSystemLanguage() {
    final systemLocales = PlatformDispatcher.instance.locales;
    for (final locale in systemLocales) {
      final matched = AppLanguage.fromCode(locale.languageCode);
      if (matched != null) return matched;
    }
    // Aucune langue système supportée → fallback français (règle produit absolue)
    return AppLanguage.fallback;
  }
}
