import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/backup_job_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/backup_providers.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(backupJobsProvider(salonId));
    final notifier = ref.watch(backupNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sauvegardes de données')),
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
                message: 'Impossible de charger les sauvegardes.',
                onRetry: () => ref.invalidate(backupJobsProvider(salonId)),
              ),
              data: (jobs) => jobs.isEmpty
                  ? KynzaEmptyState(
                      icon: Icons.cloud_done_outlined,
                      title: 'Aucune sauvegarde',
                      subtitle:
                          'Créez votre première sauvegarde pour archiver vos données.',
                      ctaLabel: 'Créer une sauvegarde',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Créer une sauvegarde'),
        content: const Text(
          'Les données des 90 derniers jours (réservations, clients, prestations, personnel, avis, factures) seront exportées et stockées de manière sécurisée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: AppColors.primary),
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
        message: 'Sauvegarde créée avec succès.',
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: KynzaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Sauvegarde sécurisée', style: AppTypography.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Exportez vos données dans un fichier JSON chiffré stocké sur nos serveurs. Une sauvegarde maximum toutes les 6 heures.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaButton(
              label: 'Créer une sauvegarde',
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
                  Text(
                    _formatDate(job.createdAt),
                    style: AppTypography.body,
                  ),
                  if (job.recordsExported != null || sizeLabel != null)
                    Text(
                      [
                        if (job.recordsExported != null)
                          '${job.recordsExported} enregistrements',
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