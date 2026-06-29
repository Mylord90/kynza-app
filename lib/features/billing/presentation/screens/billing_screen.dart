import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';

const _planNames = {'free': 'Gratuit', 'pro': 'Pro', 'premium': 'Premium'};

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Facturation')),
      body: salon == null
          ? const Center(child: KynzaSpinner())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                KynzaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plan actuel', style: AppTypography.bodySmall),
                      Text(
                        _planNames[salon.plan] ?? salon.plan,
                        style: AppTypography.h1,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (salon.planStartedAt != null) ...[
                        const Text(
                          'Période en cours',
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          _periodLabel(salon.plan, salon.planStartedAt!),
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      const Text(
                        'Méthode de paiement : Manuelle (virement bancaire)',
                        style: AppTypography.bodySmall,
                      ),
                      if (salon.plan != 'free' &&
                          salon.planStartedAt != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Prochaine facturation : ${_nextBillingLabel(salon.plan, salon.planStartedAt!)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                KynzaCard(
                  onTap: () => context.push(RouteNames.ownerSubscription),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Gérer mon abonnement',
                          style: AppTypography.h3,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                KynzaCard(
                  onTap: () => context.push(RouteNames.ownerBillingInvoices),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Historique des factures',
                          style: AppTypography.h3,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
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
