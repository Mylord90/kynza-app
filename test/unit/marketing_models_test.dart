import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/marketing/client_contact_model.dart';
import 'package:kynza/core/models/marketing/promotion_model.dart';

void main() {
  group('ClientContactModelX.isKynzaUser', () {
    test('true once the contact is linked to a KYNZA user account', () {
      const contact = ClientContactModel(
        salonId: 's1',
        ownerId: 'o1',
        clientUserId: 'u1',
        fullName: 'Aline N.',
      );
      expect(contact.isKynzaUser, isTrue);
    });

    test('false for an external, manually-entered contact', () {
      const contact = ClientContactModel(
        salonId: 's1',
        ownerId: 'o1',
        fullName: 'Aline N.',
      );
      expect(contact.isKynzaUser, isFalse);
    });
  });

  group('ClientContactModelX.isInvitePending', () {
    test('false when no invite has been sent yet', () {
      const contact = ClientContactModel(
        salonId: 's1',
        ownerId: 'o1',
        fullName: 'Aline N.',
      );
      expect(contact.isInvitePending, isFalse);
    });

    test('true once sent but not yet accepted', () {
      final contact = ClientContactModel(
        salonId: 's1',
        ownerId: 'o1',
        fullName: 'Aline N.',
        inviteSentAt: DateTime(2026, 1, 1),
      );
      expect(contact.isInvitePending, isTrue);
    });

    test('false once the invite has been accepted', () {
      final contact = ClientContactModel(
        salonId: 's1',
        ownerId: 'o1',
        fullName: 'Aline N.',
        inviteSentAt: DateTime(2026, 1, 1),
        inviteAcceptedAt: DateTime(2026, 1, 2),
      );
      expect(contact.isInvitePending, isFalse);
    });
  });

  group('PromotionModelX.formattedDiscount', () {
    test('renders a percent discount as "-X%"', () {
      final promo = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountValue: 20,
        startsAt: DateTime(2026, 1, 1),
        endsAt: DateTime(2026, 2, 1),
      );
      expect(promo.formattedDiscount, '-20%');
    });

    test('renders a fixed BIF discount with the currency formatter', () {
      final promo = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountType: DiscountType.fixedBif,
        discountValue: 5000,
        startsAt: DateTime(2026, 1, 1),
        endsAt: DateTime(2026, 2, 1),
      );
      expect(promo.formattedDiscount, contains('FBu'));
      expect(promo.formattedDiscount, startsWith('-'));
    });
  });

  group('PromotionModelX time windows', () {
    final now = DateTime.now();

    test('isExpired is true once endsAt is in the past', () {
      final promo = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountValue: 10,
        startsAt: now.subtract(const Duration(days: 10)),
        endsAt: now.subtract(const Duration(days: 1)),
      );
      expect(promo.isExpired, isTrue);
    });

    test('isExpired is false while endsAt is still in the future', () {
      final promo = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountValue: 10,
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 10)),
      );
      expect(promo.isExpired, isFalse);
    });

    test('isStarted is true once startsAt has passed', () {
      final promo = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountValue: 10,
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 10)),
      );
      expect(promo.isStarted, isTrue);
    });

    test('isLive requires active + started + not expired all at once', () {
      final live = PromotionModel(
        salonId: 's1',
        title: 'Promo',
        discountValue: 10,
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 10)),
      );
      expect(live.isLive, isTrue);

      final inactive = live.copyWith(isActive: false);
      expect(inactive.isLive, isFalse);

      final notYetStarted = live.copyWith(
        startsAt: now.add(const Duration(days: 1)),
      );
      expect(notYetStarted.isLive, isFalse);

      final expired = live.copyWith(
        endsAt: now.subtract(const Duration(hours: 1)),
      );
      expect(expired.isLive, isFalse);
    });
  });

  group('DiscountTypeConverter', () {
    const converter = DiscountTypeConverter();

    test('round-trips percent and fixedBif', () {
      for (final type in DiscountType.values) {
        expect(converter.fromJson(converter.toJson(type)), type);
      }
    });

    test('maps the snake_case "fixed_bif" db value correctly', () {
      expect(converter.fromJson('fixed_bif'), DiscountType.fixedBif);
      expect(converter.toJson(DiscountType.fixedBif), 'fixed_bif');
    });
  });
}
