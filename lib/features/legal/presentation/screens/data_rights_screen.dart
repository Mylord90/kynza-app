import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';
import '../widgets/legal_labels.dart';

class DataRightsScreen extends ConsumerWidget {
  const DataRightsScreen({super.key});

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dataRightsDeletionConfirmTitle),
        content: Text(context.l10n.dataRightsDeletionConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.dataRightsDeletionButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(dataDeletionNotifierProvider.notifier).requestDeletion();
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: context.l10n.dataRightsRequestSubmitted,
        level: ToastLevel.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: e is AppException
            ? e.message
            : context.l10n.dataRightsRequestsLoadError,
        level: ToastLevel.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(dataDeletionRequestsProvider);
    final submitting = ref.watch(dataDeletionNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.dataRightsTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  context.l10n.dataRightsExportSectionTitle,
                  style: AppTypography.h2,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.dataRightsExportDescription,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                KynzaButton(
                  label: context.l10n.dataRightsExportButton,
                  variant: KynzaButtonVariant.secondary,
                  onPressed: () =>
                      context.push(RouteNames.legalSupportContact),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.dataRightsDeletionSectionTitle,
                  style: AppTypography.h2,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.dataRightsDeletionDescription,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                KynzaButton(
                  label: context.l10n.dataRightsDeletionButton,
                  isLoading: submitting,
                  onPressed: () => _confirmDeletion(context, ref),
                ),
                const SizedBox(height: AppSpacing.xl),
                requestsAsync.when(
                  loading: () => const KynzaSkeleton(height: 120),
                  error: (_, __) => KynzaErrorState(
                    message: context.l10n.dataRightsRequestsLoadError,
                    onRetry: () =>
                        ref.invalidate(dataDeletionRequestsProvider),
                  ),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          context.l10n.dataRightsRequestsEmptySubtitle,
                          style: AppTypography.bodySmall,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final request in requests)
                          KynzaCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                dataDeletionStatusLabel(
                                  context,
                                  request.status,
                                ),
                              ),
                              subtitle: request.requestedAt != null
                                  ? Text(
                                      request.requestedAt!
                                          .toLocal()
                                          .toString(),
                                      style: AppTypography.bodySmall,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
