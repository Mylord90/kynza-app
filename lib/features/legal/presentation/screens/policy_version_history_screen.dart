import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';

class PolicyVersionHistoryScreen extends ConsumerWidget {
  const PolicyVersionHistoryScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(legalDocumentBySlugProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.policyVersionHistoryTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: documentAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: KynzaSkeleton(height: 300),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.policyVersionHistoryLoadError,
                onRetry: () =>
                    ref.invalidate(legalDocumentBySlugProvider(slug)),
              ),
              data: (document) {
                if (document?.id == null) {
                  return KynzaErrorState(
                    message: context.l10n.policyVersionHistoryLoadError,
                    onRetry: () =>
                        ref.invalidate(legalDocumentBySlugProvider(slug)),
                  );
                }
                final versionsAsync = ref.watch(
                  legalVersionHistoryProvider(document!.id!),
                );
                return versionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: KynzaSkeleton(height: 300),
                  ),
                  error: (_, __) => KynzaErrorState(
                    message: context.l10n.policyVersionHistoryLoadError,
                    onRetry: () => ref.invalidate(
                      legalVersionHistoryProvider(document.id!),
                    ),
                  ),
                  data: (versions) {
                    if (versions.isEmpty) {
                      return KynzaEmptyState(
                        icon: Icons.history_outlined,
                        title: context.l10n.policyVersionHistoryEmptyTitle,
                        subtitle:
                            context.l10n.policyVersionHistoryEmptySubtitle,
                        ctaLabel: context.l10n.commonBack,
                        onCta: () => Navigator.of(context).maybePop(),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: versions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final version = versions[index];
                        return KynzaCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('v${version.versionNumber}'),
                            subtitle: version.publishedAt != null
                                ? Text(
                                    version.publishedAt!.toLocal().toString(),
                                    style: AppTypography.bodySmall,
                                  )
                                : null,
                            trailing: version.isCurrent
                                ? Chip(
                                    label: Text(
                                      context
                                          .l10n
                                          .policyVersionHistoryCurrentBadge,
                                      style: AppTypography.bodySmall,
                                    ),
                                    backgroundColor: AppColors.primaryGlow,
                                  )
                                : null,
                          ),
                        );
                      },
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
