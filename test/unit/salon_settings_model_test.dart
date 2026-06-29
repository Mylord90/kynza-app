import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/salon_settings_model.dart';

void main() {
  group('SalonSettingsModel', () {
    test('fromJson applies defaults for missing columns', () {
      final settings = SalonSettingsModel.fromJson({
        'id': 's1',
        'salon_id': 'salon-1',
      });
      expect(settings.bookingAdvanceDays, 30);
      expect(settings.notifPushEnabled, true);
      expect(settings.timezone, 'Africa/Bujumbura');
      expect(settings.loyaltyRewardDescription, 'Service gratuit');
    });

    test(
      'toJson keys match the snake_case salon_settings columns used by SettingField',
      () {
        const settings = SalonSettingsModel(id: 's1', salonId: 'salon-1');
        final json = settings.toJson();
        expect(json['booking_advance_days'], 30);
        expect(json['notif_reminder_hours_before_2'], 1);
        expect(json['advanced_overbooking_limit'], 0);
      },
    );
  });
}
