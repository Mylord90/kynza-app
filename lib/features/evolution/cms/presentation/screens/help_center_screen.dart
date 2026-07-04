import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/providers/app_providers.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/cms_providers.dart';

/// Client-facing consumer of `cms_content` (type: help_article/faq) —
/// offline-cached via [CmsCache], never a blank screen even with no
/// connectivity, since Help content is exactly the thing a user reaches for
/// when something else is already broken.
class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final params = (type: 'help_article', locale: locale);
    final contentAsync = ref.watch(cmsPublishedProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.helpCenterTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: contentAsync.when(
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
                onRetry: () => ref.invalidate(cmsPublishedProvider(params)),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.help_outline,
                    title: context.l10n.helpCenterEmptyTitle,
                    subtitle: context.l10n.helpCenterEmptySubtitle,
                    ctaLabel: context.l10n.commonRetry,
                    onCta: () => ref.invalidate(cmsPublishedProvider(params)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaCard(
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(article.title, style: AppTypography.body),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                article.bodyMarkdown,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ],
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
