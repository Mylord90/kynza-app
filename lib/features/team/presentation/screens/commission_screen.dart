import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../application/providers/commission_providers.dart';

const _monthLabels = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

class CommissionScreen extends ConsumerWidget {
  const CommissionScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedCommissionMonthProvider);
    final summaryAsync = ref.watch(commissionSummaryProvider(salonId));
    final commissionsAsync = ref.watch(salonCommissionsProvider(salonId));
    final staffAsync = ref.watch(salonStaffProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(selectedCommissionMonthProvider.notifier).state =
                    DateTime(month.year, month.month - 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                ref.read(selectedCommissionMonthProvider.notifier).state =
                    DateTime(month.year, month.month + 1),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(commissionSummaryProvider(salonId));
                ref.invalidate(salonCommissionsProvider(salonId));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    '${_monthLabels[month.month - 1]} ${month.year}',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  summaryAsync.when(
                    loading: () => const KynzaSkeleton(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (summary) => Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: 'Gagné',
                            amountBif: summary.earnedBif,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Payé',
                            amountBif: summary.paidBif,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryTile(
                            label: 'En attente',
                            amountBif: summary.pendingBif,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  commissionsAsync.when(
                    loading: () => const Column(
                      children: [
                        KynzaBookingCardSkeleton(),
                        SizedBox(height: AppSpacing.sm),
                        KynzaBookingCardSkeleton(),
                        SizedBox(height: AppSpacing.sm),
                        KynzaBookingCardSkeleton(),
                        SizedBox(height: AppSpacing.sm),
                        KynzaBookingCardSkeleton(),
                      ],
                    ),
                    error: (_, __) => KynzaErrorState(
                      message: 'Impossible de charger les commissions.',
                      onRetry: () =>
                          ref.invalidate(salonCommissionsProvider(salonId)),
                    ),
                    data: (commissions) {
                      if (commissions.isEmpty) {
                        return const KynzaEmptyState(
                          icon: Icons.payments_outlined,
                          title: 'Aucune commission ce mois',
                          subtitle:
                              'Les commissions apparaîtront après les RDV terminés.',
                          ctaLabel: 'Retour',
                          onCta: _noop,
                        );
                      }
                      final pendingIds = commissions
                          .where((c) => !c.isPaid)
                          .map((c) => c.id!)
                          .toList();
                      final staffById = {
                        for (final s in staffAsync.valueOrNull ?? [])
                          if (s.id != null) s.id!: s,
                      };
                      return Column(
                        children: [
                          if (pendingIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: KynzaButton(
                                label: 'Tout marquer payé',
                                onPressed: () => ref
                                    .read(commissionNotifierProvider.notifier)
                                    .markPaid(salonId, pendingIds)
                                    .catchError((_) {}),
                              ),
                            ),
                          for (final c in commissions)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: KynzaCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        staffById[c.staffId]?.displayName ??
                                            'Staff',
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    KynzaAmountWidget(
                                      amountBif: c.amountBif,
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    KynzaBadge(
                                      label: c.isPaid ? 'PAYÉ' : 'EN ATTENTE',
                                      variant: c.isPaid
                                          ? KynzaBadgeVariant.success
                                          : KynzaBadgeVariant.warning,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.amountBif});

  final String label;
  final int amountBif;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          KynzaAmountWidget(
            amountBif: amountBif,
            style: AppTypography.amountMd,
          ),
        ],
      ),
    );
  }
}
