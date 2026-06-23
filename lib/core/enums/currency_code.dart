enum CurrencyCode {
  bif('BIF', 'FBu', 'fr_BI', 0),
  usd('USD', '\$', 'en_US', 2),
  eur('EUR', '€', 'fr_FR', 2),
  cad('CAD', 'CA\$', 'en_CA', 2),
  gbp('GBP', '£', 'en_GB', 2);

  const CurrencyCode(this.code, this.symbol, this.locale, this.decimalDigits);
  final String code;
  final String symbol;
  final String locale;
  final int decimalDigits;

  static CurrencyCode fromCode(String code) => CurrencyCode.values.firstWhere(
    (c) => c.code == code.toUpperCase(),
    orElse: () => CurrencyCode.bif,
  );
}
