enum BookingStatus {
  pendingPayment,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  static BookingStatus fromString(String v) => values.firstWhere(
    (s) => s.name == v,
    orElse: () => BookingStatus.pendingPayment,
  );
}

enum PaymentStatus { pending, processing, completed, failed, reversed, expired }

enum PlanType { free, pro, premium }

enum PlanStatus { active, gracePeriod, expired }

enum AuthProvider { email, google, facebook, apple }

enum SyncStatus { synced, syncing, pending, failed }

enum LoyaltyAction { earned, redeemed, expired }

enum DiscountType { percent, fixedBif }
