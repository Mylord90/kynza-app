import 'package:intl/intl.dart';
import '../enums/currency_code.dart';

/// KYNZA Currency Formatter
/// V1: BIF only — DB stores INT (always BIF, never decimals)
/// V2: multi-currency via CurrencyDisplayService
abstract class CurrencyFormatter {
  /// V1 primary format: "45 000 FBu"
  /// Uses narrow non-breaking space ( ) as thousands separator
  static String formatBif(int amountBif) {
    if (amountBif < 0) return '-${formatBif(-amountBif)}';
    final formatted = NumberFormat(
      '#,###',
      'fr_BI',
    ).format(amountBif).replaceAll(',', ' ');
    return '$formatted FBu';
  }

  /// Future V2: format by any currency
  static String format(num amount, CurrencyCode currency) {
    final fmt = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    );
    return fmt.format(amount);
  }

  /// Parse BIF display string back to int
  static int parseBif(String value) {
    final clean = value
        .replaceAll('FBu', '')
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .trim();
    return int.tryParse(clean) ?? 0;
  }

  /// Confidential mode: "••••• FBu"
  static String confidential() => '••••• FBu';
}
