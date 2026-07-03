import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../application/providers/commission_providers.dart';

String _monthLabel(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.commonMonthJanuary,
  2 => l10n.commonMonthFebruary,
  3 => l10n.commonMonthMarch,
  4 => l10n.commonMonthApril,
  5 => l10n.commonMonthMay,
  6 => l10n.commonMonthJune,
  7 => l10n.commonMonthJuly,
  8 => l10n.commonMonthAugust,
  9 => l10n.commonMonthSeptember,
  10 => l10n.commonMonthOctober,
  11 => l10n.commonMonthNovember,
  _ => l10n.commonMonthDecember,
};

class CommissionScreen extends ConsumerWidget {
  const CommissionScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedCommissionMonthProvider);
    final summaryAsync = ref.watch(commissionSummaryProvider(salonId));
    final commissionsAsync = ref.watch(salonCommissionsProvider(salonId));
    final staffAsync = ref.watch(salonStaffProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.staffCommissionsTitle),
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
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                ref.invalidate(commissionSummaryProvider(salonId));
                ref.invalidate(salonCommissionsProvider(salonId));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    '${_monthLabel(l10n, month.month)} ${month.year}',
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
                            label: l10n.staffDetailCommissionsEarned,
                            amountBif: summary.earnedBif,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryTile(
                            label: l10n.staffDetailCommissionsPaid,
                            amountBif: summary.paidBif,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryTile(
                            label: l10n.staffDetailCommissionsPending,
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
                      message: l10n.commissionLoadError,
                      onRetry: () =>
                          ref.invalidate(salonCommissionsProvider(salonId)),
                    ),
                    data: (commissions) {
                      if (commissions.isEmpty) {
                        return KynzaEmptyState(
                          icon: Icons.payments_outlined,
                          title: l10n.commissionEmptyTitle,
                          subtitle: l10n.commissionEmptySubtitle,
                          ctaLabel: l10n.commonBack,
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
                                label: l10n.commissionMarkAllPaid,
                                onPressed: () => ref
                                    .read(commissionNotifierProvider.notifier)
                                    .markPaid(salonId, pendingIds)
                                    .catchError(CrashReportingService.recordError),
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
                                            l10n.commissionStaffFallback,
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    KynzaAmountWidget(
                                      amountBif: c.amountBif,
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    KynzaBadge(
                                      label: c.isPaid
                                          ? l10n.commissionBadgePaid
                                          : l10n.commissionBadgePending,
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
