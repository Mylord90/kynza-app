import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_qr_token_model.freezed.dart';
part 'loyalty_qr_token_model.g.dart';

@freezed
class LoyaltyQrTokenModel with _$LoyaltyQrTokenModel {
  const factory LoyaltyQrTokenModel({
    required String id,
    required String cardId,
    required String salonId,
    required String clientId,
    required DateTime expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
  }) = _LoyaltyQrTokenModel;

  factory LoyaltyQrTokenModel.fromSupabase(Map<String, dynamic> json) =>
      LoyaltyQrTokenModel.fromJson(json);

  factory LoyaltyQrTokenModel.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyQrTokenModelFromJson(json);
}
