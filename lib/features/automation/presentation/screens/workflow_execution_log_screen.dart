import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/automation_workflow_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/automation_providers.dart';

Color _statusColor(String status) => switch (status) {
  'success' => AppColors.success,
  'failed' => AppColors.error,
  'skipped' => AppColors.textMuted,
  _ => AppColors.warning,
};

class WorkflowExecutionLogScreen extends ConsumerWidget {
  const WorkflowExecutionLogScreen({
    super.key,
    required this.salonId,
    this.workflowId,
    this.workflowName,
  });

  final String salonId;
  final String? workflowId;
  final String? workflowName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (salonId: salonId, workflowId: workflowId);
    final logsAsync = ref.watch(automationExecutionLogsProvider(query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(workflowName ?? context.l10n.automationLogHistoryTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: logsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 64),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.automationLogLoadError,
                onRetry: () =>
                    ref.invalidate(automationExecutionLogsProvider(query)),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.history_outlined,
                    title: context.l10n.automationLogEmptyTitle,
                    subtitle: context.l10n.automationLogEmptySubtitle,
                    ctaLabel: context.l10n.commonBack,
                    onCta: _noop,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: logs.length,
                  itemBuilder: (context, index) =>
                      _ExecutionLogTile(log: logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _ExecutionLogTile extends ConsumerStatefulWidget {
  const _ExecutionLogTile({required this.log});

  final AutomationExecutionLogModel log;

  @override
  ConsumerState<_ExecutionLogTile> createState() => _ExecutionLogTileState();
}

class _ExecutionLogTileState extends ConsumerState<_ExecutionLogTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(log.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(log.triggerType, style: AppTypography.body),
                ),
                Text(
                  log.status,
                  style: AppTypography.bodySmall.copyWith(
                    color: _statusColor(log.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (log.startedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${log.startedAt!.day}/${log.startedAt!.month} '
                  '${log.startedAt!.hour.toString().padLeft(2, '0')}:'
                  '${log.startedAt!.minute.toString().padLeft(2, '0')}'
                  ' · ${log.actionsExecuted} action(s) réussie(s)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (log.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  log.errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (_expanded) _ActionRunsList(executionLogId: log.id),
          ],
        ),
      ),
    );
  }
}

class _ActionRunsList extends ConsumerWidget {
  const _ActionRunsList({required this.executionLogId});

  final String executionLogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(automationActionRunsProvider(executionLogId));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: runsAsync.when(
        loading: () => const KynzaSkeleton(height: 32),
        error: (_, __) => Text(
          context.l10n.automationLogLoadDetailError,
          style: AppTypography.bodySmall,
        ),
        data: (runs) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: runs
              .map(
                (run) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: _statusColor(run.status),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          run.lastError ?? run.status,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      if (run.attemptCount > 1)
                        Text(
                          '${run.attemptCount}x',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
