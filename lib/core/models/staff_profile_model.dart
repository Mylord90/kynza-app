import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_profile_model.freezed.dart';
part 'staff_profile_model.g.dart';

@freezed
class StaffProfileModel with _$StaffProfileModel {
  const factory StaffProfileModel({
    String? id,
    String? userId,
    required String salonId,
    @Default('staff') String role,
    required String displayName,
    String? bio,
    String? avatarUrl,
    String? phone,
    @Default(<String>[]) List<String> specialties,
    @Default(true) bool isActive,
    String? invitedBy,
    String? invitationToken,
    DateTime? invitationAcceptedAt,
    @Default('percent') String commissionType,
    @Default(0) num commissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _StaffProfileModel;

  factory StaffProfileModel.fromSupabase(Map<String, dynamic> json) =>
      StaffProfileModel.fromJson(json);

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StaffProfileModelFromJson(json);
}

extension StaffProfileModelX on StaffProfileModel {
  bool get isPending => invitationAcceptedAt == null;
  bool get isManager => role == 'manager';
}
