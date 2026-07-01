import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';

Map<String, String> _planNames(BuildContext context) => {
  'free': context.l10n.billingPlanNameFree,
  'pro': context.l10n.billingPlanNamePro,
  'premium': context.l10n.billingPlanNamePremium,
};

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.billingTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: salon == null
                ? const KynzaLoaderInline(size: KynzaLoaderSize.large)
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      KynzaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.billingCurrentPlanLabel,
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              _planNames(context)[salon.plan] ?? salon.plan,
                              style: AppTypography.h1,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (salon.planStartedAt != null) ...[
                              Text(
                                context.l10n.billingCurrentPeriodLabel,
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                _periodLabel(salon.plan, salon.planStartedAt!),
                                style: AppTypography.body,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            Text(
                              context.l10n.billingPaymentMethodManual,
                              style: AppTypography.bodySmall,
                            ),
                            if (salon.plan != 'free' &&
                                salon.planStartedAt != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.l10n.billingNextBillingLabel(
                                  _nextBillingLabel(
                                    salon.plan,
                                    salon.planStartedAt!,
                                  ),
                                ),
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      KynzaCard(
                        onTap: () => context.push(RouteNames.ownerSubscription),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                context.l10n.billingManageSubscriptionButton,
                                style: AppTypography.h3,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      KynzaCard(
                        onTap: () =>
                            context.push(RouteNames.ownerBillingInvoices),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                context.l10n.billingInvoiceHistoryButton,
                                style: AppTypography.h3,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(String plan, DateTime startedAt) {
    final end = plan == 'year'
        ? DateTime(startedAt.year + 1, startedAt.month, startedAt.day)
        : DateTime(startedAt.year, startedAt.month + 1, startedAt.day);
    return '${_formatDate(startedAt)} → ${_formatDate(end)}';
  }

  String _nextBillingLabel(String plan, DateTime startedAt) {
    final next = plan == 'premium'
        ? DateTime(startedAt.year + 1, startedAt.month, startedAt.day)
        : DateTime(startedAt.year, startedAt.month + 1, startedAt.day);
    return _formatDate(next);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
