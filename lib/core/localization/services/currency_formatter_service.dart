import '../../../core/utils/currency_formatter.dart';

/// Locale-aware currency helpers for KYNZA.
///
/// The BIF/FBu format ("45 000 FBu") is IMMUTABLE — it must never change
/// regardless of locale. This class delegates to [CurrencyFormatter] for
/// all BIF operations, providing a single localization-aware access point.
class CurrencyFormatterService {
  const CurrencyFormatterService(this.locale);

  final String locale;

  /// "45 000 FBu" — format is immutable across all locales.
  String formatBif(int amount) => CurrencyFormatter.formatBif(amount);

  /// "••••• FBu" — confidential mode.
  String confidential() => CurrencyFormatter.confidential();

  /// Parse "45 000 FBu" → 45000.
  int? parseBif(String formatted) => CurrencyFormatter.parseBif(formatted);

  static CurrencyFormatterService of(String locale) =>
      CurrencyFormatterService(locale);
}
