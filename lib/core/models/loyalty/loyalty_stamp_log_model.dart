import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/app_enums.dart';

part 'loyalty_stamp_log_model.freezed.dart';
part 'loyalty_stamp_log_model.g.dart';

class LoyaltyActionConverter extends JsonConverter<LoyaltyAction, String> {
  const LoyaltyActionConverter();

  @override
  LoyaltyAction fromJson(String json) => LoyaltyAction.values.firstWhere(
    (a) => a.name == json,
    orElse: () => LoyaltyAction.earned,
  );

  @override
  String toJson(LoyaltyAction object) => object.name;
}

@freezed
class LoyaltyStampLogModel with _$LoyaltyStampLogModel {
  const factory LoyaltyStampLogModel({
    String? id,
    required String cardId,
    required String salonId,
    required String clientId,
    String? bookingId,
    @LoyaltyActionConverter()
    @Default(LoyaltyAction.earned)
    LoyaltyAction action,
    required int stampsDelta,
    String? note,
    DateTime? createdAt,
  }) = _LoyaltyStampLogModel;

  factory LoyaltyStampLogModel.fromSupabase(Map<String, dynamic> json) =>
      LoyaltyStampLogModel.fromJson(json);

  factory LoyaltyStampLogModel.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyStampLogModelFromJson(json);
}
