import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/automation_workflow_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/automation_providers.dart';

const _operators = ['eq', 'neq', 'gt', 'lt', 'gte', 'lte', 'in', 'contains'];
const _targets = ['client', 'owner', 'staff'];
const _severities = ['debug', 'info', 'warning', 'error', 'critical'];

class WorkflowBuilderScreen extends ConsumerStatefulWidget {
  const WorkflowBuilderScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<WorkflowBuilderScreen> createState() =>
      _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends ConsumerState<WorkflowBuilderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _triggerType;
  final List<AutomationConditionModel> _conditions = [];
  final List<AutomationActionModel> _actions = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addCondition() {
    setState(
      () => _conditions.add(
        AutomationConditionModel(
          field: '',
          operator: 'eq',
          value: '',
          orderIndex: _conditions.length,
        ),
      ),
    );
  }

  void _addAction(String actionType) {
    setState(
      () => _actions.add(
        AutomationActionModel(
          actionType: actionType,
          orderIndex: _actions.length,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _triggerType == null) {
      showKynzaToast(
        context,
        message: 'Le nom et le déclencheur sont requis.',
        level: ToastLevel.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(automationWorkflowNotifierProvider.notifier)
          .createWorkflow(
            salonId: widget.salonId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            triggerType: _triggerType!,
            conditions: _conditions,
            actions: _actions,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showKynzaToast(
        context,
        message: 'Impossible de créer ce workflow.',
        level: ToastLevel.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final triggerTypesAsync = ref.watch(automationTriggerTypesProvider);
    final actionTypesAsync = ref.watch(automationActionTypesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nouveau workflow')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KynzaTextField(label: 'Nom', controller: _nameController),
          const SizedBox(height: AppSpacing.md),
          KynzaTextField(
            label: 'Description (optionnel)',
            controller: _descriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          triggerTypesAsync.when(
            loading: () => const KynzaSkeleton(height: 56),
            error: (_, __) =>
                const Text('Impossible de charger les déclencheurs.'),
            data: (triggers) => KynzaDropdown<String>(
              label: 'Déclencheur',
              value: _triggerType,
              items: triggers.map((t) => t.id).toList(),
              itemLabel: (id) {
                final trigger = triggers.firstWhere((t) => t.id == id);
                return '${trigger.label}${trigger.wired ? '' : ' (pas encore câblé)'}';
              },
              onChanged: (value) => setState(() => _triggerType = value),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Conditions', style: AppTypography.h2),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addCondition,
              ),
            ],
          ),
          if (_conditions.isEmpty)
            const Text(
              "Aucune condition — le workflow s'exécutera à chaque déclenchement.",
              style: AppTypography.bodySmall,
            ),
          for (var i = 0; i < _conditions.length; i++)
            _ConditionRow(
              condition: _conditions[i],
              showLogicalOperator: i > 0,
              onChanged: (updated) => setState(() => _conditions[i] = updated),
              onRemove: () => setState(() => _conditions.removeAt(i)),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actions', style: AppTypography.h2),
              actionTypesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (actionTypes) => PopupMenuButton<String>(
                  icon: const Icon(Icons.add_circle_outline),
                  onSelected: _addAction,
                  itemBuilder: (context) => [
                    for (final type in actionTypes)
                      PopupMenuItem(
                        value: type.id,
                        child: Text(
                          type.implemented
                              ? type.label
                              : '${type.label} (bientôt)',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_actions.isEmpty)
            const Text(
              'Ajoutez au moins une action à exécuter.',
              style: AppTypography.bodySmall,
            ),
          for (var i = 0; i < _actions.length; i++)
            _ActionRow(
              action: _actions[i],
              onChanged: (updated) => setState(() => _actions[i] = updated),
              onRemove: () => setState(() => _actions.removeAt(i)),
            ),
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: 'Créer le workflow',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.condition,
    required this.showLogicalOperator,
    required this.onChanged,
    required this.onRemove,
  });

  final AutomationConditionModel condition;
  final bool showLogicalOperator;
  final void Function(AutomationConditionModel) onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: KynzaCard(
        child: Column(
          children: [
            if (showLogicalOperator)
              Align(
                alignment: Alignment.centerLeft,
                child: KynzaDropdown<String>(
                  label: 'Opérateur logique',
                  value: condition.logicalOperator,
                  items: const ['AND', 'OR'],
                  itemLabel: (v) => v,
                  onChanged: (v) => onChanged(
                    condition.copyWith(logicalOperator: v ?? 'AND'),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: KynzaTextField(
                    label: 'Champ (ex. amount)',
                    controller: TextEditingController(text: condition.field),
                    onChanged: (v) => onChanged(condition.copyWith(field: v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: KynzaDropdown<String>(
                    label: 'Opérateur',
                    value: condition.operator,
                    items: _operators,
                    itemLabel: (v) => v,
                    onChanged: (v) =>
                        onChanged(condition.copyWith(operator: v ?? 'eq')),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: KynzaTextField(
                    label: 'Valeur',
                    controller: TextEditingController(
                      text: '${condition.value}',
                    ),
                    onChanged: (v) => onChanged(condition.copyWith(value: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.onChanged,
    required this.onRemove,
  });

  final AutomationActionModel action;
  final void Function(AutomationActionModel) onChanged;
  final VoidCallback onRemove;

  void _setParam(String key, dynamic value) {
    final params = {...action.params, key: value};
    onChanged(action.copyWith(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: KynzaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(action.actionType, style: AppTypography.body),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
            ..._paramFields(),
            Row(
              children: [
                const Text(
                  'Délai (secondes) : ',
                  style: AppTypography.bodySmall,
                ),
                Expanded(
                  child: KynzaTextField(
                    controller: TextEditingController(
                      text: '${action.delaySeconds}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onChanged(
                      action.copyWith(delaySeconds: int.tryParse(v) ?? 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _paramFields() {
    switch (action.actionType) {
      case 'send_notification':
      case 'send_whatsapp':
        return [
          KynzaTextField(
            label: 'Événement (event_type)',
            hint: 'ex. booking_confirmed',
            controller: TextEditingController(
              text: '${action.params['event'] ?? ''}',
            ),
            onChanged: (v) => _setParam('event', v),
          ),
          KynzaDropdown<String>(
            label: 'Destinataire',
            value: action.params['target'] as String? ?? 'client',
            items: _targets,
            itemLabel: (v) => v,
            onChanged: (v) => _setParam('target', v ?? 'client'),
          ),
        ];
      case 'add_loyalty_bonus':
        return [
          KynzaTextField(
            label: 'Tampons bonus',
            controller: TextEditingController(
              text: '${action.params['stamps'] ?? 1}',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _setParam('stamps', int.tryParse(v) ?? 1),
          ),
          KynzaTextField(
            label: 'Raison (optionnel)',
            controller: TextEditingController(
              text: '${action.params['reason'] ?? ''}',
            ),
            onChanged: (v) => _setParam('reason', v),
          ),
        ];
      case 'log_activity':
        return [
          KynzaTextField(
            label: 'Action',
            controller: TextEditingController(
              text: '${action.params['action'] ?? ''}',
            ),
            onChanged: (v) => _setParam('action', v),
          ),
          KynzaDropdown<String>(
            label: 'Sévérité',
            value: action.params['severity'] as String? ?? 'info',
            items: _severities,
            itemLabel: (v) => v,
            onChanged: (v) => _setParam('severity', v ?? 'info'),
          ),
        ];
      case 'stamp_loyalty':
        return const [];
      default:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              "Cette action n'est pas encore exécutée par le moteur (voir PHASE_2_SUMMARY.md).",
              style: AppTypography.bodySmall,
            ),
          ),
        ];
    }
  }
}
