import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/marketing/client_contact_model.dart';
import '../../../../core/models/marketing/promotion_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/marketing_repository.dart';

class MarketingRepositoryImpl implements MarketingRepository {
  static const _contactsTable = 'client_contacts';
  static const _promotionsTable = 'promotions';
  static const _discountType = DiscountTypeConverter();

  @override
  Stream<List<ClientContactModel>> getContacts(String salonId) {
    return SupabaseService.client
        .from(_contactsTable)
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(ClientContactModel.fromSupabase)
                  .toList()
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                    a.createdAt ?? DateTime(0),
                  ),
                ),
        );
  }

  @override
  Future<ClientContactModel> addContact(ClientContactModel contact) async {
    try {
      final row = await SupabaseService.from(_contactsTable)
          .insert({
            'salon_id': contact.salonId,
            'owner_id': contact.ownerId,
            'client_user_id': contact.clientUserId,
            'full_name': contact.fullName,
            'phone': contact.phone,
            'email': contact.email,
            'notes': contact.notes,
            'source': contact.source,
          })
          .select()
          .single();
      return ClientContactModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible d'ajouter ce contact.");
    }
  }

  @override
  Future<int> importFromBookings(String salonId) async {
    try {
      final salon = await SupabaseService.from(
        'salons',
      ).select('owner_id').eq('id', salonId).single();
      final ownerId = salon['owner_id'] as String;

      final bookingRows = await SupabaseService.from('bookings')
          .select('client_id, users:client_id(full_name, phone, email)')
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null);

      final byClient = <String, Map<String, dynamic>>{};
      for (final row in bookingRows) {
        final clientId = row['client_id'] as String;
        byClient.putIfAbsent(
          clientId,
          () => (row['users'] as Map<String, dynamic>?) ?? const {},
        );
      }

      final existingRows = await SupabaseService.from(_contactsTable)
          .select('client_user_id')
          .eq('salon_id', salonId)
          .not('client_user_id', 'is', null);
      final existingIds = existingRows
          .map((r) => r['client_user_id'] as String)
          .toSet();

      final toInsert = byClient.entries
          .where((e) => !existingIds.contains(e.key))
          .toList();
      if (toInsert.isEmpty) return 0;

      await SupabaseService.from(_contactsTable).insert([
        for (final entry in toInsert)
          {
            'salon_id': salonId,
            'owner_id': ownerId,
            'client_user_id': entry.key,
            'full_name': entry.value['full_name'] ?? 'Client',
            'phone': entry.value['phone'],
            'email': entry.value['email'],
            'source': 'booking',
          },
      ]);
      return toInsert.length;
    } catch (_) {
      throw const AppException("Impossible d'importer vos clients.");
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    try {
      await SupabaseService.from(
        _contactsTable,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce contact.');
    }
  }

  @override
  Stream<List<PromotionModel>> getPromotions(String salonId) {
    return SupabaseService.client
        .from(_promotionsTable)
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(PromotionModel.fromSupabase)
                  .toList()
                ..sort((a, b) => b.endsAt.compareTo(a.endsAt)),
        );
  }

  @override
  Future<PromotionModel> createPromotion(PromotionModel promotion) async {
    try {
      final row = await SupabaseService.from(_promotionsTable)
          .insert({
            'salon_id': promotion.salonId,
            'title': promotion.title,
            'description': promotion.description,
            'discount_type': _discountType.toJson(promotion.discountType),
            'discount_value': promotion.discountValue,
            'service_id': promotion.serviceId,
            'min_booking_bif': promotion.minBookingBif,
            'max_uses': promotion.maxUses,
            'promo_code': promotion.promoCode,
            'starts_at': promotion.startsAt.toIso8601String(),
            'ends_at': promotion.endsAt.toIso8601String(),
          })
          .select()
          .single();
      return PromotionModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de créer cette promotion.');
    }
  }

  @override
  Future<PromotionModel> updatePromotion(PromotionModel promotion) async {
    try {
      final row = await SupabaseService.from(_promotionsTable)
          .update({
            'title': promotion.title,
            'description': promotion.description,
            'discount_type': _discountType.toJson(promotion.discountType),
            'discount_value': promotion.discountValue,
            'service_id': promotion.serviceId,
            'min_booking_bif': promotion.minBookingBif,
            'max_uses': promotion.maxUses,
            'promo_code': promotion.promoCode,
            'starts_at': promotion.startsAt.toIso8601String(),
            'ends_at': promotion.endsAt.toIso8601String(),
            'is_active': promotion.isActive,
          })
          .eq('id', promotion.id as Object)
          .select()
          .single();
      return PromotionModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de modifier cette promotion.');
    }
  }

  @override
  Future<void> deactivatePromotion(String id) async {
    try {
      await SupabaseService.from(
        _promotionsTable,
      ).update({'is_active': false}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de désactiver cette promotion.');
    }
  }

  @override
  Future<String> getOrCreateSalonReferralToken(
    String salonId,
    String ownerId,
  ) async {
    try {
      final existing = await SupabaseService.from('referrals')
          .select('referral_token')
          .eq('referrer_id', ownerId)
          .eq('salon_id', salonId)
          .isFilter('referred_id', null)
          .maybeSingle();
      if (existing != null) return existing['referral_token'] as String;

      final row = await SupabaseService.from('referrals')
          .insert({'referrer_id': ownerId, 'salon_id': salonId})
          .select('referral_token')
          .single();
      return row['referral_token'] as String;
    } catch (_) {
      throw const AppException("Impossible de générer le lien d'invitation.");
    }
  }
}
