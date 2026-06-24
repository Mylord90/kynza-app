import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_kpi_model.freezed.dart';
part 'salon_kpi_model.g.dart';

/// One row of `public.v_salon_kpis` — daily aggregate for a salon.
@freezed
class SalonKpiModel with _$SalonKpiModel {
  const factory SalonKpiModel({
    required String salonId,
    required DateTime day,
    @Default(0) int bookingsTotal,
    @Default(0) int bookingsCompleted,
    @Default(0) int bookingsCancelled,
    @Default(0) int bookingsNoShow,
    @Default(0) int revenueBif,
    @Default(0) double noShowRate,
    @Default(0) double cancellationRate,
  }) = _SalonKpiModel;

  factory SalonKpiModel.fromSupabase(Map<String, dynamic> json) =>
      SalonKpiModel.fromJson(json);

  factory SalonKpiModel.fromJson(Map<String, dynamic> json) =>
      _$SalonKpiModelFromJson(json);
}
