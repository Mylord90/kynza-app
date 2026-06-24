import '../../../../core/models/marketing/client_contact_model.dart';
import '../../../../core/models/marketing/promotion_model.dart';

abstract class MarketingRepository {
  Stream<List<ClientContactModel>> getContacts(String salonId);
  Future<ClientContactModel> addContact(ClientContactModel contact);
  Future<int> importFromBookings(String salonId);
  Future<void> deleteContact(String id);
  Stream<List<PromotionModel>> getPromotions(String salonId);
  Future<PromotionModel> createPromotion(PromotionModel promotion);
  Future<PromotionModel> updatePromotion(PromotionModel promotion);
  Future<void> deactivatePromotion(String id);

  /// A single reusable, salon-wide invite link for the owner to share —
  /// distinct from the per-contact tokens on [ClientContactModel].
  Future<String> getOrCreateSalonReferralToken(String salonId, String ownerId);
}
