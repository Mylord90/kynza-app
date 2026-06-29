import 'package:freezed_annotation/freezed_annotation.dart';

part 'cohort_retention_model.freezed.dart';
part 'cohort_retention_model.g.dart';

/// One row returned by the `get_cohort_retention` RPC — what fraction of
/// a monthly client cohort returned `monthOffset` months later (0-3).
@freezed
class CohortRetentionModel with _$CohortRetentionModel {
  const factory CohortRetentionModel({
    required DateTime cohortMonth,
    required int monthOffset,
    @Default(0) int cohortSize,
    @Default(0) int retainedCount,
  }) = _CohortRetentionModel;

  factory CohortRetentionModel.fromSupabase(Map<String, dynamic> json) =>
      CohortRetentionModel.fromJson(json);

  factory CohortRetentionModel.fromJson(Map<String, dynamic> json) =>
      _$CohortRetentionModelFromJson(json);
}

extension CohortRetentionModelX on CohortRetentionModel {
  double get retentionPct =>
      cohortSize <= 0 ? 0.0 : (retainedCount / cohortSize).clamp(0.0, 1.0);
}
