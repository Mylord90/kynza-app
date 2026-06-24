import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_service_model.freezed.dart';
part 'top_service_model.g.dart';

/// One row of `public.v_top_services` — booking/revenue aggregate per
/// service for a given month.
@freezed
class TopServiceModel with _$TopServiceModel {
  const factory TopServiceModel({
    required String salonId,
    required String serviceId,
    required String serviceName,
    required int priceBif,
    @Default(0) int bookingCount,
    @Default(0) int totalRevenueBif,
    required DateTime month,
  }) = _TopServiceModel;

  factory TopServiceModel.fromSupabase(Map<String, dynamic> json) =>
      TopServiceModel.fromJson(json);

  factory TopServiceModel.fromJson(Map<String, dynamic> json) =>
      _$TopServiceModelFromJson(json);
}
