import '../../../../core/models/automation_workflow_model.dart';

abstract class AutomationRepository {
  Future<List<AutomationTriggerTypeModel>> getTriggerTypes();

  Future<List<AutomationActionTypeModel>> getActionTypes();

  Future<List<AutomationWorkflowModel>> getWorkflows(String salonId);

  Future<AutomationWorkflowModel> createWorkflow({
    required String salonId,
    required String name,
    String? description,
    required String triggerType,
    required List<AutomationConditionModel> conditions,
    required List<AutomationActionModel> actions,
  });

  Future<void> setWorkflowActive(String workflowId, bool isActive);

  Future<void> deleteWorkflow(String workflowId);

  Future<List<AutomationExecutionLogModel>> getExecutionLogs(
    String salonId, {
    String? workflowId,
    int limit = 20,
  });

  Future<List<AutomationActionRunModel>> getActionRuns(String executionLogId);
}
