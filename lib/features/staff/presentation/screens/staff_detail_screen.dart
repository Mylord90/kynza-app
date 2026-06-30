import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../dashboard/presentation/widgets/kynza_bar_chart_fl.dart';
import '../../../dashboard/presentation/widgets/kynza_simple_bar_chart.dart'
    show BarData;
import '../../../team/application/providers/commission_providers.dart';
import '../../application/providers/staff_providers.dart';
import 'staff_form_screen.dart';

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

final _staffRecentBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, staffId) async {
      final rows = await SupabaseService.from('bookings')
          .select('*, client:users!client_id(*), service:services(*)')
          .eq('practitioner_id', staffId)
          .isFilter('deleted_at', null)
          .order('start_time', ascending: false)
          .limit(5);
      return rows.map(BookingModel.fromSupabase).toList();
    });

class StaffDetailScreen extends ConsumerWidget {
  const StaffDetailScreen({super.key, required this.staff});

  final StaffProfileModel staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isOwner = profile?.role == UserRole.owner;
    final monthlyAsync = ref.watch(_staffMonthlyBookingsProvider(staff.id!));
    final recentAsync = ref.watch(_staffRecentBookingsProvider(staff.id!));
    final commissionsAsync = isOwner
        ? ref.watch(staffCommissionsProvider(staff.id!))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(staff.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StaffFormScreen(staff: staff)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_staffMonthlyBookingsProvider(staff.id!));
                ref.invalidate(_staffRecentBookingsProvider(staff.id!));
                if (isOwner) {
                  ref.invalidate(staffCommissionsProvider(staff.id!));
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'staff-avatar-${staff.id}',
                          child: KynzaAvatar(
                            fullName: staff.displayName,
                            avatarUrl: staff.avatarUrl,
                            size: AvatarSize.xl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(staff.displayName, style: AppTypography.h2),
                        Text(
                          staff.role == 'manager'
                              ? context.l10n.staffRoleManager
                              : context.l10n.staffRoleStaff,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(context.l10n.staffDetailPerformanceMonth, style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  monthlyAsync.when(
                    loading: () => const KynzaSkeleton(height: 180),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (bookings) {
                      final byDay = <int, int>{};
                      for (final b in bookings) {
                        if (b.status.name != 'completed') continue;
                        byDay[b.startTime.day] =
                            (byDay[b.startTime.day] ?? 0) + 1;
                      }
                      final days = byDay.keys.toList()..sort();
                      return KynzaBarChartFl(
                        title: '',
                        bars: [
                          for (final d in days)
                            BarData(label: '$d', value: byDay[d]!),
                        ],
                      );
                    },
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(context.l10n.staffDetailCommissionsMonth, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.md),
                    commissionsAsync!.when(
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
                              child: _StatTile(
                                label: context.l10n.staffDetailCommissionsEarned,
                                amountBif: paid + pending,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatTile(
                                label: context.l10n.staffDetailCommissionsPaid,
                                amountBif: paid,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatTile(
                                label: context.l10n.staffDetailCommissionsPending,
                                amountBif: pending,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(context.l10n.staffDetailServicesTitle, style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  staff.specialties.isEmpty
                      ? Text(
                          context.l10n.staffDetailNoSpecialty,
                          style: AppTypography.bodySmall,
                        )
                      : Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            for (final s in staff.specialties)
                              KynzaBadge(label: s),
                          ],
                        ),
                  const SizedBox(height: AppSpacing.xl),
                  KynzaCard(
                    onTap: () => context.push(
                      RouteNames.ownerAvailabilityStaffPath(staff.id!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_outlined, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(context.l10n.staffDetailScheduleLabel, style: AppTypography.h3),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(context.l10n.staffDetailLastBookings, style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  recentAsync.when(
                    loading: () => const KynzaSkeleton(height: 48, count: 3),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (bookings) => bookings.isEmpty
                        ? Text(
                            context.l10n.staffDetailNoBookings,
                            style: AppTypography.bodySmall,
                          )
                        : Column(
                            children: [
                              for (final b in bookings)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: KynzaCard(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${b.startTime.day}/${b.startTime.month}/${b.startTime.year}',
                                            style: AppTypography.body,
                                          ),
                                        ),
                                        Text(
                                          // b.status.name is an enum raw value — not translated
                                          b.status.name,
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: AppSpacing.xl),
                    KynzaButton(
                      label: staff.isActive
                          ? context.l10n.staffDetailDeactivate
                          : context.l10n.staffDetailReactivate,
                      variant: KynzaButtonVariant.secondary,
                      onPressed: () => ref
                          .read(staffNotifierProvider.notifier)
                          .toggleActive(staff.id!, !staff.isActive)
                          .catchError((_) {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaButton(
                      label: staff.role == 'manager'
                          ? context.l10n.staffDetailDemote
                          : context.l10n.staffDetailPromote,
                      variant: KynzaButtonVariant.secondary,
                      onPressed: () => ref
                          .read(staffNotifierProvider.notifier)
                          .updateStaff(
                            staff.copyWith(
                              role: staff.role == 'manager'
                                  ? 'staff'
                                  : 'manager',
                            ),
                          )
                          .catchError((_) {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaButton(
                      label: context.l10n.staffDetailRemoveButton,
                      variant: KynzaButtonVariant.destructive,
                      onPressed: () async {
                        final confirmed = await showKynzaConfirmDialog(
                          context,
                          title: context.l10n.staffDetailRemoveConfirmTitle,
                          message: context.l10n.staffDetailRemoveConfirmMessage(staff.displayName),
                        );
                        if (!confirmed) return;
                        try {
                          await ref
                              .read(staffNotifierProvider.notifier)
                              .remove(staff.id!);
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (context.mounted) {
                            showKynzaToast(
                              context,
                              message: e is AppException
                                  ? e.message
                                  : context.l10n.errorGeneric,
                              level: ToastLevel.error,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.amountBif});

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
