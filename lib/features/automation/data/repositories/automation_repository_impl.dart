import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/automation_workflow_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/automation_repository.dart';

class AutomationRepositoryImpl implements AutomationRepository {
  @override
  Future<List<AutomationTriggerTypeModel>> getTriggerTypes() async {
    try {
      final rows = await SupabaseService.from(
        'automation_trigger_types',
      ).select().order('category');
      return rows.map(AutomationTriggerTypeModel.fromJson).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les déclencheurs.');
    }
  }

  @override
  Future<List<AutomationActionTypeModel>> getActionTypes() async {
    try {
      final rows = await SupabaseService.from(
        'automation_action_types',
      ).select().order('category');
      return rows.map(AutomationActionTypeModel.fromJson).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les actions.');
    }
  }

  @override
  Future<List<AutomationWorkflowModel>> getWorkflows(String salonId) async {
    try {
      final rows = await SupabaseService.from('automation_workflows')
          .select()
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .order('is_system', ascending: false)
          .order('created_at');
      return rows.map(AutomationWorkflowModel.fromJson).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les workflows.');
    }
  }

  @override
  Future<AutomationWorkflowModel> createWorkflow({
    required String salonId,
    required String name,
    String? description,
    required String triggerType,
    required List<AutomationConditionModel> conditions,
    required List<AutomationActionModel> actions,
  }) async {
    try {
      final workflowRow = await SupabaseService.from('automation_workflows')
          .insert({
            'salon_id': salonId,
            'name': name,
            'description': description,
            'trigger_type': triggerType,
          })
          .select()
          .single();
      final workflow = AutomationWorkflowModel.fromJson(workflowRow);

      if (conditions.isNotEmpty) {
        await SupabaseService.from('automation_conditions').insert([
          for (final c in conditions)
            {
              'workflow_id': workflow.id,
              'field': c.field,
              'operator': c.operator,
              'value': c.value,
              'logical_operator': c.logicalOperator,
              'order_index': c.orderIndex,
            },
        ]);
      }

      if (actions.isNotEmpty) {
        await SupabaseService.from('automation_actions').insert([
          for (final a in actions)
            {
              'workflow_id': workflow.id,
              'action_type': a.actionType,
              'params': a.params,
              'delay_seconds': a.delaySeconds,
              'order_index': a.orderIndex,
            },
        ]);
      }

      return workflow;
    } catch (_) {
      throw const AppException('Impossible de créer ce workflow.');
    }
  }

  @override
  Future<void> setWorkflowActive(String workflowId, bool isActive) async {
    try {
      await SupabaseService.from(
        'automation_workflows',
      ).update({'is_active': isActive}).eq('id', workflowId);
    } catch (_) {
      throw const AppException('Impossible de modifier ce workflow.');
    }
  }

  @override
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      await SupabaseService.from('automation_workflows')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', workflowId);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce workflow.');
    }
  }

  @override
  Future<List<AutomationExecutionLogModel>> getExecutionLogs(
    String salonId, {
    String? workflowId,
    int limit = 20,
  }) async {
    try {
      var query = SupabaseService.from(
        'automation_execution_logs',
      ).select().eq('salon_id', salonId);
      if (workflowId != null) query = query.eq('workflow_id', workflowId);
      final rows = await query
          .order('started_at', ascending: false)
          .limit(limit);
      return rows.map(AutomationExecutionLogModel.fromJson).toList();
    } catch (_) {
      throw const AppException(
        "Impossible de charger l'historique d'exécution.",
      );
    }
  }

  @override
  Future<List<AutomationActionRunModel>> getActionRuns(
    String executionLogId,
  ) async {
    try {
      final rows = await SupabaseService.from(
        'automation_action_runs',
      ).select().eq('execution_log_id', executionLogId).order('created_at');
      return rows.map(AutomationActionRunModel.fromJson).toList();
    } catch (_) {
      throw const AppException(
        "Impossible de charger le détail de l'exécution.",
      );
    }
  }
}
