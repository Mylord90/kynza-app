abstract class KynzaConstants {
  static const appName = 'KYNZA';
  static const defaultCurrency = 'BIF';
  static const defaultLocale = 'fr_BI';
  static const defaultCountry = 'BI';
  static const phonePrefix = '+257';
  static const maxFreeBookings = 20;
  static const sessionDays = 7;
  static const maxPromoPerWeek = 2;
  static const bookingTimeoutMin = 30;
  static const slotLockMin = 5;
  static const noShowGraceMin = 15;
  static const maxNoteChars = 500;
  static const reliabilityStart = 100;
  static const noShowPenalty = 1;
  static const noShowThreshold = 3;
  static const gracePeriodDays = 3;

  // TODO(billing): placeholder — replace with KYNZA's real bank account
  // details before any real upgrade request is sent to a client.
  static const bankTransferInstructions =
      'Banque : [À CONFIGURER]\n'
      'Titulaire du compte : KYNZA SARL\n'
      'Numéro de compte : [À CONFIGURER]\n'
      "Merci d'inclure la référence ci-dessus dans le motif du virement.";
}
