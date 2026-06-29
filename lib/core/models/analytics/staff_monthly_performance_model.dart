import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_monthly_performance_model.freezed.dart';
part 'staff_monthly_performance_model.g.dart';

/// One row of `public.v_staff_monthly_performance`. Revenue must never be
/// shown to a non-owner viewer (R11), same restriction as [TopStaffModel]
/// — enforced in the display layer, not here.
@freezed
class StaffMonthlyPerformanceModel with _$StaffMonthlyPerformanceModel {
  const factory StaffMonthlyPerformanceModel({
    required String salonId,
    required String staffId,
    required String displayName,
    String? avatarUrl,
    required DateTime month,
    @Default(0) int completions,
    @Default(0) int noShows,
    @Default(0) int cancellations,
    @Default(0) int revenueBif,
    double? avgRating,
  }) = _StaffMonthlyPerformanceModel;

  factory StaffMonthlyPerformanceModel.fromSupabase(
    Map<String, dynamic> json,
  ) => StaffMonthlyPerformanceModel.fromJson(json);

  factory StaffMonthlyPerformanceModel.fromJson(Map<String, dynamic> json) =>
      _$StaffMonthlyPerformanceModelFromJson(json);
}
