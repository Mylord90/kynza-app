import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/feature_flag_audit_providers.dart';

/// Read-only history of who changed which flag override, when, and to what
/// value — built on the existing `activity_logs` audit trail (Phase 10 of
/// this pass will build the full cross-domain audit engine/query layer on
/// top of the same table; this screen is a narrow, flag-scoped view, not a
/// duplicate pipeline).
class FeatureFlagAuditScreen extends ConsumerWidget {
  const FeatureFlagAuditScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(featureFlagAuditLogProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionFeatureFlagsAuditTitle)),
      body: entriesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: KynzaSkeleton(height: 64),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.errorLoadFailed,
          onRetry: () => ref.invalidate(featureFlagAuditLogProvider(salonId)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.history,
              title: context.l10n.evolutionFeatureFlagsAuditEmptyTitle,
              subtitle: context.l10n.evolutionFeatureFlagsAuditEmptySubtitle,
              ctaLabel: context.l10n.commonRetry,
              onCta: () => ref.invalidate(featureFlagAuditLogProvider(salonId)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: KynzaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            entry.typeAction == 'feature_flag_override_removed'
                                ? Icons.remove_circle_outline
                                : Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              entry.flagKey ?? '',
                              style: AppTypography.body,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${entry.scope ?? '?'} · ${entry.target ?? '?'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.createdAt.toLocal().toString(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
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
    );
  }
}
