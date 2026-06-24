import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral_model.freezed.dart';
part 'referral_model.g.dart';

@freezed
class ReferralModel with _$ReferralModel {
  const factory ReferralModel({
    String? id,
    required String referrerId,
    String? referredId,
    String? salonId,
    required String referralToken,
    @Default('pending') String status,
    @Default(false) bool rewardGranted,
    @Default(1) int rewardStamps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ReferralModel;

  factory ReferralModel.fromSupabase(Map<String, dynamic> json) =>
      ReferralModel.fromJson(json);

  factory ReferralModel.fromJson(Map<String, dynamic> json) =>
      _$ReferralModelFromJson(json);
}
