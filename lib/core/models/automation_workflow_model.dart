import 'package:freezed_annotation/freezed_annotation.dart';

part 'automation_workflow_model.freezed.dart';
part 'automation_workflow_model.g.dart';

@freezed
class AutomationTriggerTypeModel with _$AutomationTriggerTypeModel {
  const factory AutomationTriggerTypeModel({
    required String id,
    required String label,
    String? description,
    required String category,
    @Default(false) bool wired,
  }) = _AutomationTriggerTypeModel;

  factory AutomationTriggerTypeModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationTriggerTypeModelFromJson(json);
}

@freezed
class AutomationActionTypeModel with _$AutomationActionTypeModel {
  const factory AutomationActionTypeModel({
    required String id,
    required String label,
    String? description,
    required String category,
    @Default(true) bool implemented,
  }) = _AutomationActionTypeModel;

  factory AutomationActionTypeModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationActionTypeModelFromJson(json);
}

@freezed
class AutomationWorkflowModel with _$AutomationWorkflowModel {
  const factory AutomationWorkflowModel({
    required String id,
    required String salonId,
    required String name,
    String? description,
    required String triggerType,
    @Default(true) bool isActive,
    @Default(false) bool isSystem,
    @Default(0) int priority,
    @Default(0) int executionCount,
    DateTime? lastExecutedAt,
  }) = _AutomationWorkflowModel;

  factory AutomationWorkflowModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationWorkflowModelFromJson(json);
}

@freezed
class AutomationConditionModel with _$AutomationConditionModel {
  const factory AutomationConditionModel({
    String? id,
    required String field,
    required String operator,
    required dynamic value,
    @Default('AND') String logicalOperator,
    @Default(0) int orderIndex,
  }) = _AutomationConditionModel;

  factory AutomationConditionModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationConditionModelFromJson(json);
}

@freezed
class AutomationActionModel with _$AutomationActionModel {
  const factory AutomationActionModel({
    String? id,
    required String actionType,
    @Default(<String, dynamic>{}) Map<String, dynamic> params,
    @Default(0) int delaySeconds,
    @Default(0) int orderIndex,
  }) = _AutomationActionModel;

  factory AutomationActionModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationActionModelFromJson(json);
}

@freezed
class AutomationActionRunModel with _$AutomationActionRunModel {
  const factory AutomationActionRunModel({
    required String id,
    required String actionId,
    required String status,
    @Default(0) int attemptCount,
    DateTime? scheduledAt,
    String? lastError,
    DateTime? executedAt,
  }) = _AutomationActionRunModel;

  factory AutomationActionRunModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationActionRunModelFromJson(json);
}

@freezed
class AutomationExecutionLogModel with _$AutomationExecutionLogModel {
  const factory AutomationExecutionLogModel({
    required String id,
    required String workflowId,
    required String triggerType,
    Map<String, dynamic>? triggerContext,
    required String status,
    String? errorMessage,
    @Default(0) int actionsExecuted,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMs,
    @Default(<AutomationActionRunModel>[])
    List<AutomationActionRunModel> actionRuns,
  }) = _AutomationExecutionLogModel;

  factory AutomationExecutionLogModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationExecutionLogModelFromJson(json);
}
