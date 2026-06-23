import '../utils/currency_formatter.dart';

/// KYNZA Currency Display Service
/// V1: always BIF regardless of country
/// V2: will convert based on payerCountryCode via exchange rate API
class CurrencyDisplayService {
  static const CurrencyDisplayService instance = CurrencyDisplayService._();
  const CurrencyDisplayService._();

  /// V1: always BIF
  String display(int amountBif, {bool confidential = false}) {
    if (confidential) return CurrencyFormatter.confidential();
    return CurrencyFormatter.formatBif(amountBif);
  }

  /// V2 hook (no-op in V1)
  String displayForPayer(
    int amountBif,
    String payerCountryCode, {
    bool confidential = false,
  }) {
    if (confidential) return CurrencyFormatter.confidential();
    // V1: ignore payerCountryCode
    // V2: lookup rate, convert, format in payer's currency
    return CurrencyFormatter.formatBif(amountBif);
  }
}
