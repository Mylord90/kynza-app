import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/loyalty/loyalty_card_model.dart';
import 'package:kynza/core/models/loyalty/loyalty_program_model.dart';
import 'package:kynza/core/models/loyalty/loyalty_qr_token_model.dart';
import 'package:kynza/core/models/loyalty/loyalty_stamp_log_model.dart';

void main() {
  group('LoyaltyCardModelX.progressPct', () {
    test('returns 0.0 when no stamps earned yet', () {
      const card = LoyaltyCardModel(salonId: 's1', clientId: 'c1');
      expect(card.progressPct(10), 0.0);
    });

    test('returns the correct fraction for a partial card', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 3,
      );
      expect(card.progressPct(10), closeTo(0.3, 0.0001));
    });

    test('clamps at 1.0 when stamps exceed the requirement', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 15,
      );
      expect(card.progressPct(10), 1.0);
    });

    test('returns 0.0 when required is zero or negative (guard)', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 5,
      );
      expect(card.progressPct(0), 0.0);
    });
  });

  group('LoyaltyCardModelX.isComplete', () {
    test('false below the required stamp count', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 9,
      );
      expect(card.isComplete(10), isFalse);
    });

    test('true at exactly the required stamp count', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 10,
      );
      expect(card.isComplete(10), isTrue);
    });

    test('stays true when stamps overflow past the requirement', () {
      const card = LoyaltyCardModel(
        salonId: 's1',
        clientId: 'c1',
        stampsCount: 12,
      );
      expect(card.isComplete(10), isTrue);
    });
  });

  group('LoyaltyProgramModelX.formattedReward', () {
    test('includes the BIF value when one is set', () {
      const program = LoyaltyProgramModel(
        salonId: 's1',
        rewardDescription: '1 coupe offerte',
        rewardValueBif: 15000,
      );
      expect(program.formattedReward, contains('1 coupe offerte'));
      expect(program.formattedReward, contains('FBu'));
    });

    test('omits the value suffix when rewardValueBif is zero', () {
      const program = LoyaltyProgramModel(
        salonId: 's1',
        rewardDescription: '1 coupe offerte',
      );
      expect(program.formattedReward, '1 coupe offerte');
    });
  });

  group('LoyaltyActionConverter', () {
    const converter = LoyaltyActionConverter();

    test('round-trips earned/redeemed/expired', () {
      for (final action in LoyaltyAction.values) {
        expect(converter.fromJson(converter.toJson(action)), action);
      }
    });

    test('falls back to earned for an unrecognized value', () {
      expect(converter.fromJson('not_a_real_action'), LoyaltyAction.earned);
    });
  });

  group('LoyaltyStampLogModel', () {
    test('defaults action to earned', () {
      const log = LoyaltyStampLogModel(
        cardId: 'card1',
        salonId: 's1',
        clientId: 'c1',
        stampsDelta: 1,
      );
      expect(log.action, LoyaltyAction.earned);
    });
  });

  group('LoyaltyQrTokenModel.fromSupabase', () {
    test('parses snake_case columns into the model fields', () {
      final token = LoyaltyQrTokenModel.fromSupabase({
        'id': 'tok1',
        'card_id': 'card1',
        'salon_id': 's1',
        'client_id': 'c1',
        'expires_at': '2026-06-27T10:10:00.000Z',
        'used_at': null,
        'created_at': '2026-06-27T10:00:00.000Z',
      });
      expect(token.id, 'tok1');
      expect(token.cardId, 'card1');
      expect(token.salonId, 's1');
      expect(token.clientId, 'c1');
      expect(token.usedAt, isNull);
      expect(token.expiresAt, DateTime.parse('2026-06-27T10:10:00.000Z'));
    });
  });
}
