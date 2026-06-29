import 'package:freezed_annotation/freezed_annotation.dart';

part 'churn_risk_model.freezed.dart';
part 'churn_risk_model.g.dart';

/// One row of `public.v_churn_risk` — a client who hasn't visited in
/// 15+ days, bucketed into a risk_level by days since their last visit.
@freezed
class ChurnRiskModel with _$ChurnRiskModel {
  const factory ChurnRiskModel({
    required String salonId,
    required String clientId,
    required String clientName,
    DateTime? lastVisitAt,
    @Default(0) int daysSinceLastVisit,
    @Default('low') String riskLevel,
  }) = _ChurnRiskModel;

  factory ChurnRiskModel.fromSupabase(Map<String, dynamic> json) =>
      ChurnRiskModel.fromJson(json);

  factory ChurnRiskModel.fromJson(Map<String, dynamic> json) =>
      _$ChurnRiskModelFromJson(json);
}
