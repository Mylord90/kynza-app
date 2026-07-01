import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/backup_job_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/backup_providers.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final jobsAsync = ref.watch(backupJobsProvider(salonId));
    final notifier = ref.watch(backupNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.dataPlatformBackupTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          _BackupInfoCard(
            isLoading: notifier.isLoading,
            onBackup: () => _startBackup(context, ref),
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 72),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: l10n.dataPlatformBackupLoadError,
                onRetry: () => ref.invalidate(backupJobsProvider(salonId)),
              ),
              data: (jobs) => jobs.isEmpty
                  ? KynzaEmptyState(
                      icon: Icons.cloud_done_outlined,
                      title: l10n.dataPlatformBackupEmptyTitle,
                      subtitle: l10n.dataPlatformBackupEmptySubtitle,
                      ctaLabel: l10n.dataPlatformBackupCreateCta,
                      onCta: () => _startBackup(context, ref),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) =>
                          _BackupJobTile(job: jobs[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.dataPlatformBackupDialogTitle),
        content: Text(l10n.dataPlatformBackupDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.commonConfirm,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(backupNotifierProvider.notifier).createBackup(salonId);
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: context.l10n.dataPlatformBackupCreateSuccess,
        level: ToastLevel.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        level: ToastLevel.error,
      );
    }
  }
}

class _BackupInfoCard extends StatelessWidget {
  const _BackupInfoCard({required this.isLoading, required this.onBackup});

  final bool isLoading;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: KynzaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.dataPlatformBackupSecureTitle,
                  style: AppTypography.h3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.dataPlatformBackupSecureSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaButton(
              label: l10n.dataPlatformBackupCreateButton,
              isLoading: isLoading,
              onPressed: isLoading ? null : onBackup,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupJobTile extends StatelessWidget {
  const _BackupJobTile({required this.job});

  final BackupJobModel job;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (job.status) {
      'completed' => (Icons.check_circle_outline, AppColors.success),
      'failed' => (Icons.error_outline, AppColors.error),
      'running' => (Icons.sync, AppColors.warning),
      _ => (Icons.hourglass_empty, AppColors.textMuted),
    };

    final sizeLabel = job.fileSizeBytes != null
        ? _formatBytes(job.fileSizeBytes!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(job.createdAt), style: AppTypography.body),
                  if (job.recordsExported != null || sizeLabel != null)
                    Text(
                      [
                        if (job.recordsExported != null)
                          context.l10n.dataPlatformBackupRecordsExported(
                            job.recordsExported!,
                          ),
                        if (sizeLabel != null) sizeLabel,
                      ].join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (job.errorMessage != null)
                    Text(
                      job.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
            KynzaBadge(label: job.status.toUpperCase()),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
