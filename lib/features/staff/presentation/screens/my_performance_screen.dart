import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../dashboard/presentation/widgets/kynza_bar_chart_fl.dart';
import '../../../dashboard/presentation/widgets/kynza_simple_bar_chart.dart'
    show BarData;
import '../../../team/application/providers/commission_providers.dart';

final _staffWeekRankProvider = FutureProvider.family<(int, int), String>((
  ref,
  staffId,
) async {
  final rows = await SupabaseService.client.rpc(
    'get_staff_week_rank',
    params: {'p_staff_id': staffId},
  );
  final row = (rows as List).first as Map<String, dynamic>;
  return (row['rank'] as int, row['team_size'] as int);
});

final _staffMonthlyBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, staffId) async {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final rows = await SupabaseService.from('bookings')
          .select()
          .eq('practitioner_id', staffId)
          .gte('start_time', monthStart.toIso8601String())
          .lt('start_time', monthEnd.toIso8601String())
          .isFilter('deleted_at', null)
          .order('start_time');
      return rows.map(BookingModel.fromSupabase).toList();
    });

final _staffReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  staffId,
) async {
  final bookingRows = await SupabaseService.from(
    'bookings',
  ).select('id').eq('practitioner_id', staffId).isFilter('deleted_at', null);
  final bookingIds = bookingRows.map((r) => r['id'] as String).toList();
  if (bookingIds.isEmpty) return [];
  final rows = await SupabaseService.from('reviews')
      .select()
      .inFilter('booking_id', bookingIds)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false)
      .limit(5);
  return rows.map(ReviewModel.fromSupabase).toList();
});

/// Staff's own performance view — R11: only ever this staff member's own
/// figures, never a colleague's. [staffCommissionsProvider] is reused
/// as-is from the owner-facing StaffDetailScreen — RLS's
/// staff_own_commissions_select policy already scopes it to the caller's
/// own rows regardless of who's viewing.
class MyPerformanceScreen extends ConsumerWidget {
  const MyPerformanceScreen({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(_staffWeekRankProvider(staffId));
    final monthlyAsync = ref.watch(_staffMonthlyBookingsProvider(staffId));
    final reviewsAsync = ref.watch(_staffReviewsProvider(staffId));
    final commissionsAsync = ref.watch(staffCommissionsProvider(staffId));
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_staffWeekRankProvider(staffId));
        ref.invalidate(_staffMonthlyBookingsProvider(staffId));
        ref.invalidate(_staffReviewsProvider(staffId));
        ref.invalidate(staffCommissionsProvider(staffId));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          monthlyAsync.when(
            loading: () => const KynzaSkeleton(height: 90),
            error: (_, __) => const SizedBox.shrink(),
            data: (bookings) {
              final thisWeek = bookings.where(
                (b) =>
                    !b.startTime.isBefore(weekStart) &&
                    b.startTime.isBefore(
                      weekStart.add(const Duration(days: 7)),
                    ),
              );
              final completed = thisWeek
                  .where((b) => b.status.name == 'completed')
                  .toList();
              final revenue = completed.fold(0, (sum, b) => sum + b.amountBif);
              return Row(
                children: [
                  Expanded(
                    child: KynzaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mes RDV', style: AppTypography.bodySmall),
                          Text(
                            '${completed.length}',
                            style: AppTypography.amountMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: KynzaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mon CA', style: AppTypography.bodySmall),
                          KynzaAmountWidget(
                            amountBif: revenue,
                            style: AppTypography.amountMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          rankAsync.when(
            loading: () => const KynzaSkeleton(height: 56),
            error: (_, __) => const SizedBox.shrink(),
            data: (result) {
              final (rank, teamSize) = result;
              if (rank == 0) return const SizedBox.shrink();
              return KynzaCard(
                child: Text(
                  '$rank${_ordinalSuffix(rank)} sur $teamSize cette semaine',
                  style: AppTypography.h3,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Mes RDV ce mois', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          monthlyAsync.when(
            loading: () => const KynzaSkeleton(height: 180),
            error: (_, __) => const SizedBox.shrink(),
            data: (bookings) {
              final byDay = <int, int>{};
              for (final b in bookings) {
                if (b.status.name != 'completed') continue;
                byDay[b.startTime.day] = (byDay[b.startTime.day] ?? 0) + 1;
              }
              final days = byDay.keys.toList()..sort();
              if (days.isEmpty) {
                return const Text(
                  'Aucun RDV terminé ce mois.',
                  style: AppTypography.bodySmall,
                );
              }
              return KynzaBarChartFl(
                title: '',
                bars: [
                  for (final d in days) BarData(label: '$d', value: byDay[d]!),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Mes avis récents', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          reviewsAsync.when(
            loading: () => const KynzaSkeleton(height: 56, count: 3),
            error: (_, __) => const SizedBox.shrink(),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Text(
                  'Aucun avis pour le moment.',
                  style: AppTypography.bodySmall,
                );
              }
              final avg =
                  reviews.fold(0, (sum, r) => sum + r.rating) / reviews.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⭐ ${avg.toStringAsFixed(1)} / 5',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final r in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '★' * r.rating + '☆' * (5 - r.rating),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            if (r.comment != null && r.comment!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(r.comment!, style: AppTypography.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Mes commissions ce mois', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          commissionsAsync.when(
            loading: () => const KynzaSkeleton(height: 56),
            error: (_, __) => const SizedBox.shrink(),
            data: (commissions) {
              final paid = commissions
                  .where((c) => c.isPaid)
                  .fold(0, (sum, c) => sum + c.amountBif);
              final pending = commissions
                  .where((c) => !c.isPaid)
                  .fold(0, (sum, c) => sum + c.amountBif);
              return Row(
                children: [
                  Expanded(
                    child: KynzaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payé', style: AppTypography.bodySmall),
                          KynzaAmountWidget(
                            amountBif: paid,
                            style: AppTypography.amountMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: KynzaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'En attente',
                            style: AppTypography.bodySmall,
                          ),
                          KynzaAmountWidget(
                            amountBif: pending,
                            style: AppTypography.amountMd,
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
    );
  }
}

String _ordinalSuffix(int n) => n == 1 ? 'er' : 'ème';
