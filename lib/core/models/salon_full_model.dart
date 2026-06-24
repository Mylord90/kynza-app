import 'package:freezed_annotation/freezed_annotation.dart';
import 'salon_media_model.dart';
import 'working_hour_model.dart';

part 'salon_full_model.freezed.dart';
part 'salon_full_model.g.dart';

@freezed
class SalonFullModel with _$SalonFullModel {
  const factory SalonFullModel({
    required String id,
    required String name,
    String? ownerId,
    @Default('free') String plan,
    @Default('active') String planStatus,
    @Default('BI') String countryCode,
    @Default('BIF') String currency,
    @Default(true) bool isOnline,
    @Default(0) int employeesCount,
    @Default(0) int monthlyBookingsCount,
    String? slogan,
    String? description,
    String? phone,
    String? email,
    String? address,
    String? province,
    String? commune,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? coverUrl,
    @Default(false) bool isVerified,
    String? socialFacebook,
    String? socialInstagram,
    String? socialTiktok,
    String? socialWhatsapp,
    @Default(<WorkingHourModel>[]) List<WorkingHourModel> workingHours,
    @Default(<SalonMediaModel>[]) List<SalonMediaModel> media,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _SalonFullModel;

  factory SalonFullModel.fromSupabase(Map<String, dynamic> json) =>
      SalonFullModel.fromJson(json);

  factory SalonFullModel.fromJson(Map<String, dynamic> json) =>
      _$SalonFullModelFromJson(json);
}

extension SalonFullModelX on SalonFullModel {
  bool get isActive => deletedAt == null;
  bool get isSolo => employeesCount == 0;
}
