import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_commission_model.freezed.dart';
part 'staff_commission_model.g.dart';

@freezed
class StaffCommissionModel with _$StaffCommissionModel {
  const factory StaffCommissionModel({
    String? id,
    required String staffId,
    required String salonId,
    required String bookingId,
    required String rateType,
    required num rateValue,
    required int amountBif,
    @Default('pending') String status,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StaffCommissionModel;

  factory StaffCommissionModel.fromSupabase(Map<String, dynamic> json) =>
      StaffCommissionModel.fromJson(json);

  factory StaffCommissionModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCommissionModelFromJson(json);
}

extension StaffCommissionModelX on StaffCommissionModel {
  bool get isPaid => status == 'paid';
}

class CommissionSummary {
  const CommissionSummary({
    this.earnedBif = 0,
    this.paidBif = 0,
    this.pendingBif = 0,
  });

  final int earnedBif;
  final int paidBif;
  final int pendingBif;
}
