import 'package:freezed_annotation/freezed_annotation.dart';
import 'salon_kpi_model.dart';

part 'dashboard_summary_model.freezed.dart';

/// Computed client-side by [AnalyticsRepository.getSummary] from the daily
/// [v_salon_kpis] rows in the selected period — never fetched directly from
/// a single DB row, so unlike the other analytics models this one has no
/// fromJson/toJson (same reasoning as core/models/time_slot_model.dart).
@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @Default(0) int revenueBif,
    @Default(0) int bookingsTotal,
    @Default(0) int bookingsCompleted,
    @Default(0) int bookingsCancelled,
    @Default(0) int bookingsNoShow,
    @Default(0) double noShowRate,
    @Default(0) double cancellationRate,
    @Default(0) double occupancyRate,
    @Default(<SalonKpiModel>[]) List<SalonKpiModel> dailySeries,
    int? revenueTrendPct,
    int? bookingsTrendPct,
  }) = _DashboardSummary;
}
