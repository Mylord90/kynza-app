import 'package:freezed_annotation/freezed_annotation.dart';

part 'revenue_point_model.freezed.dart';

/// One point of a revenue series — used for both getRevenueByPeriod
/// (actualBif only, computed client-side by bucketing SalonKpiModel rows)
/// and the 12-week forecast (forecastBif only, from a linear regression
/// over the trailing actuals — see ForecastRepository). Never persisted.
@freezed
class RevenuePointModel with _$RevenuePointModel {
  const factory RevenuePointModel({
    required DateTime periodStart,
    int? actualBif,
    int? forecastBif,
  }) = _RevenuePointModel;
}
