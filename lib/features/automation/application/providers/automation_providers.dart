import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/automation_workflow_model.dart';
import '../../data/repositories/automation_repository_impl.dart';
import '../../domain/repositories/automation_repository.dart';

final automationRepositoryProvider = Provider<AutomationRepository>(
  (ref) => AutomationRepositoryImpl(),
);

final automationTriggerTypesProvider =
    FutureProvider<List<AutomationTriggerTypeModel>>(
      (ref) => ref.read(automationRepositoryProvider).getTriggerTypes(),
    );

final automationActionTypesProvider =
    FutureProvider<List<AutomationActionTypeModel>>(
      (ref) => ref.read(automationRepositoryProvider).getActionTypes(),
    );

final automationWorkflowsProvider = FutureProvider.autoDispose
    .family<List<AutomationWorkflowModel>, String>(
      (ref, salonId) =>
          ref.read(automationRepositoryProvider).getWorkflows(salonId),
    );

typedef ExecutionLogsQuery = ({String salonId, String? workflowId});

final automationExecutionLogsProvider = FutureProvider.autoDispose
    .family<List<AutomationExecutionLogModel>, ExecutionLogsQuery>(
      (ref, query) => ref
          .read(automationRepositoryProvider)
          .getExecutionLogs(query.salonId, workflowId: query.workflowId),
    );

final automationActionRunsProvider = FutureProvider.autoDispose
    .family<List<AutomationActionRunModel>, String>(
      (ref, executionLogId) =>
          ref.read(automationRepositoryProvider).getActionRuns(executionLogId),
    );

final automationWorkflowNotifierProvider =
    AsyncNotifierProvider<AutomationWorkflowNotifier, void>(
      AutomationWorkflowNotifier.new,
    );

class AutomationWorkflowNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<AutomationWorkflowModel> createWorkflow({
    required String salonId,
    required String name,
    String? description,
    required String triggerType,
    required List<AutomationConditionModel> conditions,
    required List<AutomationActionModel> actions,
  }) async {
    final workflow = await ref
        .read(automationRepositoryProvider)
        .createWorkflow(
          salonId: salonId,
          name: name,
          description: description,
          triggerType: triggerType,
          conditions: conditions,
          actions: actions,
        );
    ref.invalidate(automationWorkflowsProvider(salonId));
    return workflow;
  }

  Future<void> setActive(
    String salonId,
    String workflowId,
    bool isActive,
  ) async {
    await ref
        .read(automationRepositoryProvider)
        .setWorkflowActive(workflowId, isActive);
    ref.invalidate(automationWorkflowsProvider(salonId));
  }

  Future<void> deleteWorkflow(String salonId, String workflowId) async {
    await ref.read(automationRepositoryProvider).deleteWorkflow(workflowId);
    ref.invalidate(automationWorkflowsProvider(salonId));
  }
}
