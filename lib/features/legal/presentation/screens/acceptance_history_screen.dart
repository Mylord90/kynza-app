import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';
import '../widgets/legal_labels.dart';

class AcceptanceHistoryScreen extends ConsumerWidget {
  const AcceptanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(acceptanceHistoryEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.acceptanceHistoryTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: entriesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 56),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.acceptanceHistoryLoadError,
                onRetry: () => ref.invalidate(acceptanceHistoryEntriesProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: context.l10n.acceptanceHistoryEmptyTitle,
                    subtitle: context.l10n.acceptanceHistoryEmptySubtitle,
                    ctaLabel: context.l10n.commonBack,
                    onCta: () => Navigator.of(context).maybePop(),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final title = entry.document != null
                        ? legalDocumentTypeLabel(context, entry.document!.type)
                        : entry.acceptance.documentVersionId;
                    return KynzaCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(title),
                        subtitle: Text(
                          [
                            if (entry.version != null)
                              'v${entry.version!.versionNumber}',
                            if (entry.acceptance.acceptedAt != null)
                              entry.acceptance.acceptedAt!.toLocal().toString(),
                          ].join(' · '),
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
