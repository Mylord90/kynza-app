import '../../../../core/models/loyalty/loyalty_card_model.dart';
import '../../../../core/models/loyalty/loyalty_program_model.dart';
import '../../../../core/models/loyalty/loyalty_stamp_log_model.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyProgramModel?> getLoyaltyProgram(String salonId);
  Future<LoyaltyProgramModel> upsertProgram(LoyaltyProgramModel program);
  Future<LoyaltyCardModel?> getClientCard(String salonId, String clientId);
  Future<LoyaltyCardModel> getOrCreateCard(String salonId, String clientId);
  Future<LoyaltyCardModel> addStamp(String cardId, {String? bookingId});
  Future<LoyaltyCardModel> redeemReward(String cardId);
  Stream<List<LoyaltyCardModel>> getClientCards(String clientId);
  Future<List<LoyaltyCardModel>> getSalonCards(String salonId);
  Future<List<LoyaltyStampLogModel>> getStampLogs(String cardId);
}
