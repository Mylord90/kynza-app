import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/booking_model.dart';
import '../models/marketing/promotion_model.dart';
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

  /// The link opens AcceptInvitationScreen directly via the
  /// com.kynza.app://accept-invitation intent-filter (AndroidManifest.xml) —
  /// if KYNZA isn't installed yet the OS has nothing to hand the link to,
  /// so the invited person still needs the invitation_token read aloud or
  /// copy-pasted in that case.
  static Future<void> shareStaffInvitation({
    required String salonName,
    required String invitationToken,
  }) async {
    final link = 'com.kynza.app://accept-invitation?token=$invitationToken';
    final text =
        "Vous êtes invité(e) à rejoindre l'équipe de $salonName sur KYNZA ! "
        'Ouvrez ce lien pour rejoindre : $link';
    await Share.share(text, subject: 'Invitation KYNZA');
  }

  static Future<void> shareService(
    SalonFullModel salon,
    ServiceModel service,
  ) async {
    final text =
        '💅 ${service.name} chez ${salon.name}\n'
        '💰 ${service.formattedPrice}\n'
        '⏱️ ${service.formattedDuration}\n'
        '📱 Réservez sur KYNZA : com.kynza.app://salon/${salon.id}';
    await Share.share(text);
  }

  static Future<void> sharePromotion(
    SalonFullModel salon,
    PromotionModel promo,
  ) async {
    final text =
        '🎉 Offre spéciale chez ${salon.name} !\n'
        '${promo.title}\n'
        '💰 ${promo.formattedDiscount}\n'
        "📅 Jusqu'au ${DateFormat('dd/MM/yyyy', 'fr_FR').format(promo.endsAt)}\n"
        '📱 Profitez-en sur KYNZA : com.kynza.app://salon/${salon.id}';
    await Share.share(text);
  }

  /// The accept-referral deep link has no handler screen yet (the
  /// referrals table is forward-compatible schema only — Phase 3B wires
  /// up the actual claim flow); the message is still useful as a
  /// personalized invite text in the meantime.
  static Future<void> shareClientInvite(
    SalonFullModel salon,
    String referralToken,
  ) async {
    final text =
        '👋 ${salon.name} vous invite à rejoindre KYNZA !\n'
        'Réservez vos soins beauté en ligne 📱\n'
        "✨ Téléchargez KYNZA et bénéficiez d'un tampon de fidélité offert :\n"
        'com.kynza.app://accept-referral?token=$referralToken\n'
        '🇧🇮 La plateforme beauté premium du Burundi';
    await Share.share(text, subject: 'Invitation KYNZA');
  }

  static Future<void> shareSalonProfile(String salonId) async {
    await Share.share('com.kynza.app://salon/$salonId');
  }

  /// A client inviting a friend to KYNZA itself — no salon in context,
  /// unlike [shareClientInvite] which is an owner inviting a client to
  /// *their* salon specifically.
  static Future<void> shareGenericInvite(String referralToken) async {
    final text =
        '👋 Rejoins-moi sur KYNZA !\n'
        'Réserve tes soins beauté en ligne au Burundi 📱\n'
        "✨ Télécharge l'app et profite d'un tampon de fidélité offert :\n"
        'com.kynza.app://accept-referral?token=$referralToken';
    await Share.share(text, subject: 'Invitation KYNZA');
  }
}
