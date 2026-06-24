import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_contact_model.freezed.dart';
part 'client_contact_model.g.dart';

@freezed
class ClientContactModel with _$ClientContactModel {
  const factory ClientContactModel({
    String? id,
    required String salonId,
    required String ownerId,
    String? clientUserId,
    required String fullName,
    String? phone,
    String? email,
    String? notes,
    @Default('manual') String source,
    @Default(false) bool optedIn,
    DateTime? optedInAt,
    DateTime? inviteSentAt,
    DateTime? inviteAcceptedAt,
    String? referralToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ClientContactModel;

  factory ClientContactModel.fromSupabase(Map<String, dynamic> json) =>
      ClientContactModel.fromJson(json);

  factory ClientContactModel.fromJson(Map<String, dynamic> json) =>
      _$ClientContactModelFromJson(json);
}

extension ClientContactModelX on ClientContactModel {
  bool get isKynzaUser => clientUserId != null;
  bool get isInvitePending => inviteSentAt != null && inviteAcceptedAt == null;
}
