import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';
import '../widgets/legal_labels.dart';

class LegalCenterScreen extends ConsumerWidget {
  const LegalCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(activeLegalDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.legalCenterTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: documentsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 56),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.legalCenterLoadError,
                onRetry: () => ref.invalidate(activeLegalDocumentsProvider),
              ),
              data: (documents) {
                if (documents.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.gavel_outlined,
                    title: context.l10n.legalCenterEmptyTitle,
                    subtitle: context.l10n.legalCenterEmptySubtitle,
                    ctaLabel: context.l10n.commonRetry,
                    onCta: () => ref.invalidate(activeLegalDocumentsProvider),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: documents.length + 2,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    if (index < documents.length) {
                      final doc = documents[index];
                      return KynzaCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(legalDocumentTypeLabel(context, doc.type)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            RouteNames.legalDocumentPath(doc.slug),
                          ),
                        ),
                      );
                    }
                    if (index == documents.length) {
                      return KynzaCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_outlined),
                          title: Text(context.l10n.acceptanceHistoryTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(RouteNames.legalAcceptanceHistory),
                        ),
                      );
                    }
                    return KynzaCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.support_agent_outlined),
                        title: Text(context.l10n.supportContactTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(RouteNames.legalSupportContact),
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
