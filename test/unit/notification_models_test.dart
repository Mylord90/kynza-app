import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/notification_log_model.dart';
import 'package:kynza/core/models/notification_preferences_model.dart';
import 'package:kynza/core/models/notification_template_model.dart';

void main() {
  group('NotificationTemplateModelX.interpolate', () {
    test('replaces every {{var}} placeholder with the matching value', () {
      const template = NotificationTemplateModel(
        eventType: 'booking_created',
        titleFr: 'Nouvelle réservation ✅',
        bodyFr: 'RDV créé chez {{salon_name}} le {{date}} à {{time}}.',
      );

      final (title, body) = template.interpolate({
        'salon_name': 'KYNZA Bujumbura',
        'date': '24/06/2026',
        'time': '14:30',
      });

      expect(title, 'Nouvelle réservation ✅');
      expect(body, 'RDV créé chez KYNZA Bujumbura le 24/06/2026 à 14:30.');
    });

    test(
      'leaves an unmatched placeholder untouched rather than blanking it',
      () {
        const template = NotificationTemplateModel(
          eventType: 'staff_joined',
          titleFr: 'Nouveau membre 🎉',
          bodyFr: '{{staff_name}} a rejoint votre équipe sur KYNZA.',
        );

        final (_, body) = template.interpolate(const {});

        expect(body, '{{staff_name}} a rejoint votre équipe sur KYNZA.');
      },
    );
  });

  group('NotificationLogModelX.isUnread', () {
    test('true when isRead is false', () {
      const log = NotificationLogModel(
        userId: 'u1',
        eventType: 'booking_created',
        channel: 'in_app',
        title: 't',
        body: 'b',
      );
      expect(log.isUnread, true);
    });

    test('false once marked read', () {
      const log = NotificationLogModel(
        userId: 'u1',
        eventType: 'booking_created',
        channel: 'in_app',
        title: 't',
        body: 'b',
        isRead: true,
      );
      expect(log.isUnread, false);
    });
  });

  group('NotificationPreferencesModelX.remindersEnabled', () {
    test('true only when both reminder windows are enabled', () {
      const both = NotificationPreferencesModel(userId: 'u1');
      expect(both.remindersEnabled, true);

      const only24h = NotificationPreferencesModel(
        userId: 'u1',
        bookingReminder2h: false,
      );
      expect(only24h.remindersEnabled, false);
    });
  });
}
