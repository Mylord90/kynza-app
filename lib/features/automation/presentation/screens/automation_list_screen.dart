import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/automation_workflow_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/automation_providers.dart';
import 'workflow_builder_screen.dart';
import 'workflow_execution_log_screen.dart';

class AutomationListScreen extends ConsumerWidget {
  const AutomationListScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(automationWorkflowsProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.automationListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: context.l10n.automationListHistoryTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkflowExecutionLogScreen(salonId: salonId),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkflowBuilderScreen(salonId: salonId),
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: workflowsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 72),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.errorLoadFailed,
                onRetry: () =>
                    ref.invalidate(automationWorkflowsProvider(salonId)),
              ),
              data: (workflows) {
                if (workflows.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.bolt_outlined,
                    title: context.l10n.automationListEmptyTitle,
                    subtitle: context.l10n.automationListEmptySubtitle,
                    ctaLabel: context.l10n.automationWorkflowCreateButton,
                    onCta: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkflowBuilderScreen(salonId: salonId),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: workflows.length,
                  itemBuilder: (context, index) => _WorkflowTile(
                    salonId: salonId,
                    workflow: workflows[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTile extends ConsumerWidget {
  const _WorkflowTile({required this.salonId, required this.workflow});

  final String salonId;
  final AutomationWorkflowModel workflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkflowExecutionLogScreen(
              salonId: salonId,
              workflowId: workflow.id,
              workflowName: workflow.name,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(workflow.name, style: AppTypography.h3),
                      ),
                      if (workflow.isSystem)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.xs),
                          child: KynzaBadge(label: 'KYNZA'),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      '${workflow.triggerType} · ${context.l10n.automationWorkflowExecutionCount(workflow.executionCount)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              activeThumbColor: AppColors.primary,
              value: workflow.isActive,
              onChanged: (value) => ref
                  .read(automationWorkflowNotifierProvider.notifier)
                  .setActive(salonId, workflow.id, value),
            ),
          ],
        ),
      ),
    );
  }
}
