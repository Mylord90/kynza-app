import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_card_model.freezed.dart';
part 'loyalty_card_model.g.dart';

@freezed
class LoyaltyCardModel with _$LoyaltyCardModel {
  const factory LoyaltyCardModel({
    String? id,
    required String salonId,
    required String clientId,
    @Default(0) int stampsCount,
    @Default(0) int totalStampsEarned,
    @Default(0) int totalRedeemed,
    DateTime? lastStampAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _LoyaltyCardModel;

  factory LoyaltyCardModel.fromSupabase(Map<String, dynamic> json) =>
      LoyaltyCardModel.fromJson(json);

  factory LoyaltyCardModel.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardModelFromJson(json);
}

extension LoyaltyCardModelX on LoyaltyCardModel {
  double progressPct(int required) =>
      required <= 0 ? 0.0 : (stampsCount / required).clamp(0.0, 1.0);

  bool isComplete(int required) => stampsCount >= required;
}
