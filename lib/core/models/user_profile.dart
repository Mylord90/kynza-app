import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/user_role.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

class UserRoleConverter extends JsonConverter<UserRole, String> {
  const UserRoleConverter();

  @override
  UserRole fromJson(String json) => UserRole.fromString(json);

  @override
  String toJson(UserRole object) => object.name;
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    String? salonId,
    @UserRoleConverter() @Default(UserRole.client) UserRole role,
    @Default('') String fullName,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? avatarUrl,
    @Default(false) bool emailVerified,
    @Default(false) bool profileCompleted,
    @Default('email') String authProvider,
    @Default(100) int reliabilityScore,
    @Default('BI') String countryCode,
    @Default('BIF') String preferredCurrency,
    @Default('fr_BI') String locale,
    @Default(false) bool isSystemAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _UserProfile;

  factory UserProfile.empty(String id) => UserProfile(id: id);

  factory UserProfile.fromSupabase(Map<String, dynamic> json) =>
      UserProfile.fromJson(json);

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

extension UserProfileX on UserProfile {
  bool get isActive => deletedAt == null;
}
