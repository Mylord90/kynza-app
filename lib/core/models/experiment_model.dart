import 'package:freezed_annotation/freezed_annotation.dart';

part 'experiment_model.freezed.dart';
part 'experiment_model.g.dart';

@freezed
class ExperimentModel with _$ExperimentModel {
  const factory ExperimentModel({
    required String id,
    required String key,
    required String name,
    String? hypothesis,
    @Default('draft') String status,
    @Default({}) Map<String, dynamic> variantConfigJson,
    DateTime? startedAt,
    DateTime? endedAt,
  }) = _ExperimentModel;

  factory ExperimentModel.fromJson(Map<String, dynamic> json) =>
      _$ExperimentModelFromJson(json);
}

extension ExperimentModelX on ExperimentModel {
  Map<String, int> get variantWeights =>
      variantConfigJson.map((k, v) => MapEntry(k, (v as num).toInt()));

  bool get isRunning => status == 'running';
}
