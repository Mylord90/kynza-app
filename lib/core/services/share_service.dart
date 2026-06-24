import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/booking_model.dart';
import '../models/salon_full_model.dart';
import '../models/service_model.dart';
import '../models/staff_profile_model.dart';
import '../utils/currency_formatter.dart';

/// Native share sheet only (WhatsApp, SMS, Facebook, etc. via the OS
/// picker) — no WhatsApp Business API dependency for this kind of share.
abstract class ShareService {
  static Future<void> shareBooking({
    required BookingModel booking,
    required SalonFullModel salon,
    required ServiceModel service,
    StaffProfileModel? practitioner,
  }) async {
    final date = DateFormat('EEEE d MMMM', 'fr_FR').format(booking.startTime);
    final time = DateFormat('HH:mm').format(booking.startTime);
    final text =
        '''
✅ RDV confirmé chez ${salon.name}
📅 $date à $time
💇 ${service.name}${practitioner != null ? ' avec ${practitioner.displayName}' : ''}
💰 ${CurrencyFormatter.formatBif(booking.amountBif)}
📍 Réservé via KYNZA
''';
    await Share.share(text, subject: 'Mon RDV KYNZA');
  }

  static Future<void> shareSalon(SalonFullModel salon) async {
    final text =
        '✨ Découvrez ${salon.name} sur KYNZA — '
        'la plateforme beauté premium au Burundi.';
    await Share.share(text);
  }
}
