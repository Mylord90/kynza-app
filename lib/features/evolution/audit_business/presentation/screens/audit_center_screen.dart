import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/audit_business_providers.dart';

/// Phase 10 (Backend Enterprise Completion), Track A — the 3 genuinely new
/// audit views (security trail, RGPD trail, ProxiPay fraud heuristics).
/// Error/Performance/Sync audits are NOT re-displayed here — they already
/// exist as Health Center sections (Phase 2/5 of this pass); duplicating
/// them into a second screen would repeat the exact mistake this pass has
/// avoided at every prior checkpoint.
class AuditCenterScreen extends ConsumerWidget {
  const AuditCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionAuditCenterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KynzaCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.evolutionAuditCenterHealthCenterNote,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AuditSection(
            title: 'Security Audit Trail',
            provider: auditSecurityTrailProvider,
          ),
          _AuditSection(
            title: 'RGPD Audit Trail',
            provider: auditRgpdTrailProvider,
          ),
          _AuditSection(
            title: 'Fraud Audit — ProxiPay Anomalies',
            provider: auditFraudProxipayProvider,
          ),
        ],
      ),
    );
  }
}

class _AuditSection extends ConsumerWidget {
  const _AuditSection({required this.title, required this.provider});

  final String title;
  final FutureProvider<List<Map<String, dynamic>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(provider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(title, style: AppTypography.body),
          children: [
            rowsAsync.when(
              loading: () => const KynzaSkeleton(height: 60),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.errorLoadFailed,
                onRetry: () => ref.invalidate(provider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: context.l10n.evolutionHealthCenterEmptyTitle,
                    subtitle: context.l10n.evolutionHealthCenterEmptySubtitle,
                    ctaLabel: context.l10n.commonRetry,
                    onCta: () => ref.invalidate(provider),
                  );
                }
                return Column(
                  children: rows
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            row.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
