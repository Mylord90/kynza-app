import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_staff_model.freezed.dart';
part 'top_staff_model.g.dart';

/// One row of `public.v_top_staff` — booking/revenue aggregate per staff
/// member for a given week. Revenue must never be shown to a non-owner
/// viewer in the UI (R11) even though this model itself carries the
/// figure — the display layer (KynzaTopStaffRow) enforces that.
@freezed
class TopStaffModel with _$TopStaffModel {
  const factory TopStaffModel({
    required String salonId,
    required String staffId,
    required String displayName,
    String? avatarUrl,
    @Default(0) int bookingCount,
    @Default(0) int revenueBif,
    required DateTime weekStart,
  }) = _TopStaffModel;

  factory TopStaffModel.fromSupabase(Map<String, dynamic> json) =>
      TopStaffModel.fromJson(json);

  factory TopStaffModel.fromJson(Map<String, dynamic> json) =>
      _$TopStaffModelFromJson(json);
}
