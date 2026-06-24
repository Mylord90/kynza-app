import 'package:freezed_annotation/freezed_annotation.dart';
import '../../utils/currency_formatter.dart';

part 'loyalty_program_model.freezed.dart';
part 'loyalty_program_model.g.dart';

@freezed
class LoyaltyProgramModel with _$LoyaltyProgramModel {
  const factory LoyaltyProgramModel({
    String? id,
    required String salonId,
    @Default(10) int stampsRequired,
    required String rewardDescription,
    @Default(0) int rewardValueBif,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _LoyaltyProgramModel;

  factory LoyaltyProgramModel.fromSupabase(Map<String, dynamic> json) =>
      LoyaltyProgramModel.fromJson(json);

  factory LoyaltyProgramModel.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyProgramModelFromJson(json);
}

extension LoyaltyProgramModelX on LoyaltyProgramModel {
  String get formattedReward => rewardValueBif > 0
      ? '$rewardDescription (${CurrencyFormatter.formatBif(rewardValueBif)})'
      : rewardDescription;
}
