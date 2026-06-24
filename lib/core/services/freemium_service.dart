import '../constants/kynza_constants.dart';
import '../models/salon_full_model.dart';

enum FreemiumLevel { ok, amber, red, blocked }

/// Pure logic, no I/O — evaluated against the salon's already-loaded
/// `monthly_bookings_count` (kept current by a DB trigger on bookings,
/// not recomputed client-side).
abstract class FreemiumService {
  static FreemiumLevel evaluate(SalonFullModel salon) {
    if (salon.plan != 'free') return FreemiumLevel.ok;

    final count = salon.monthlyBookingsCount;
    const max = KynzaConstants.maxFreeBookings;
    if (count >= max) return FreemiumLevel.blocked;
    if (count >= (max * 0.9).floor()) return FreemiumLevel.red;
    if (count >= (max * 0.75).floor()) return FreemiumLevel.amber;
    return FreemiumLevel.ok;
  }

  static bool isInGracePeriod(SalonFullModel salon) =>
      salon.planStatus == 'grace_period';

  /// Paid plans (or a free plan still under its monthly quota) can always
  /// book. Grace period keeps full access for `gracePeriodDays` after a
  /// paid plan expires (R12 — data/access never disappears abruptly).
  static bool canCreateBooking(SalonFullModel salon) {
    if (salon.plan != 'free') return true;
    return evaluate(salon) != FreemiumLevel.blocked;
  }

  static String? messageFor(FreemiumLevel level, SalonFullModel salon) {
    final remaining =
        KynzaConstants.maxFreeBookings - salon.monthlyBookingsCount;
    return switch (level) {
      FreemiumLevel.ok => null,
      FreemiumLevel.amber => 'Plus que $remaining RDV gratuits ce mois.',
      FreemiumLevel.red => 'Plus que $remaining RDV. Ne perdez aucun client !',
      FreemiumLevel.blocked => 'Limite atteinte. Vos clients attendent.',
    };
  }
}
