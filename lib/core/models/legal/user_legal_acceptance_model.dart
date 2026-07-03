import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_legal_acceptance_model.freezed.dart';
part 'user_legal_acceptance_model.g.dart';

@freezed
class UserLegalAcceptanceModel with _$UserLegalAcceptanceModel {
  const factory UserLegalAcceptanceModel({
    String? id,
    required String userId,
    required String documentVersionId,
    DateTime? acceptedAt,
    String? ipHash,
    String? appVersion,
    String? platform,
    DateTime? createdAt,
  }) = _UserLegalAcceptanceModel;

  factory UserLegalAcceptanceModel.fromSupabase(Map<String, dynamic> json) =>
      UserLegalAcceptanceModel.fromJson(json);

  factory UserLegalAcceptanceModel.fromJson(Map<String, dynamic> json) =>
      _$UserLegalAcceptanceModelFromJson(json);
}
