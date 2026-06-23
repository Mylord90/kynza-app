import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_model.freezed.dart';
part 'salon_model.g.dart';

@freezed
class SalonModel with _$SalonModel {
  const factory SalonModel({
    required String id,
    required String name,
    String? ownerId,
    @Default('free') String plan,
    @Default('active') String planStatus,
    @Default('BI') String countryCode,
    @Default('BIF') String currency,
    String? address,
    @Default(true) bool isOnline,
    @Default(0) int employeesCount,
    @Default(0) int monthlyBookingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _SalonModel;

  factory SalonModel.fromSupabase(Map<String, dynamic> json) =>
      SalonModel.fromJson(json);

  factory SalonModel.fromJson(Map<String, dynamic> json) =>
      _$SalonModelFromJson(json);
}

extension SalonModelX on SalonModel {
  bool get isActive => deletedAt == null;
  bool get isSolo => employeesCount == 0;
}
