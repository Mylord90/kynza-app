import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/booking_list_card.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../../notifications/presentation/widgets/unread_count_badge.dart';
import '../../../staff/presentation/screens/my_performance_screen.dart';
import '../widgets/staff_featured_card.dart';

final _todayBookingsWithJoinsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, staffId) async {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final rows = await SupabaseService.from('bookings')
          .select('*, client:users!client_id(*), service:services(*)')
          .eq('practitioner_id', staffId)
          .gte('start_time', dayStart.toIso8601String())
          .lt('start_time', dayEnd.toIso8601String())
          .isFilter('deleted_at', null)
          .order('start_time');

      return rows.map(BookingModel.fromSupabase).toList();
    });

class HomeStaffScreen extends ConsumerStatefulWidget {
  const HomeStaffScreen({super.key});

  @override
  ConsumerState<HomeStaffScreen> createState() => _HomeStaffScreenState();
}

class _HomeStaffScreenState extends ConsumerState<HomeStaffScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(myStaffProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titleFor(_tabIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: context.l10n.homeStaffScanLoyaltyTooltip,
            onPressed: () => context.push(RouteNames.ownerLoyaltyScan),
          ),
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            tooltip: context.l10n.homeStaffAvailabilityTooltip,
            onPressed: () => context.push(RouteNames.staffAvailability),
          ),
          const UnreadCountBadge(),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 200),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.errorLoadFailed,
          onRetry: () => ref.invalidate(myStaffProfileProvider),
        ),
        data: (staff) {
          if (staff == null) {
            return KynzaEmptyState(
              icon: Icons.person_off_outlined,
              title: context.l10n.homeStaffProfileNotLinked,
              subtitle: context.l10n.homeStaffProfileNotLinkedSubtitle,
              ctaLabel: context.l10n.commonRefresh,
              onCta: _noop,
            );
          }
          return Column(
            children: [
              const KynzaOfflineBanner(),
              Expanded(
                child: switch (_tabIndex) {
                  0 => _TodayTab(staffId: staff.id!),
                  1 => _AgendaTab(staffId: staff.id!),
                  2 => _MyClientsTab(staffId: staff.id!),
                  _ => MyPerformanceScreen(staffId: staff.id!),
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.today_outlined),
            label: context.l10n.navToday,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            label: context.l10n.navCalendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: context.l10n.navClients,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            label: context.l10n.navPerformance,
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) => switch (index) {
    0 => context.l10n.navToday,
    1 => context.l10n.navCalendar,
    2 => context.l10n.navClients,
    _ => context.l10n.navPerformance,
  };
}

void _noop() {}

class _TodayTab extends ConsumerWidget {
  const _TodayTab({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_todayBookingsWithJoinsProvider(staffId));

    return bookingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: KynzaSkeleton(height: 200),
      ),
      error: (_, __) => KynzaErrorState(
        message: context.l10n.homeOwnerCalendarError,
        onRetry: () => ref.invalidate(_todayBookingsWithJoinsProvider(staffId)),
      ),
      data: (bookings) {
        final upcoming = bookings
            .where(
              (b) =>
                  b.status.name == 'confirmed' || b.status.name == 'inProgress',
            )
            .toList();
        if (upcoming.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.event_available_outlined,
            title: context.l10n.homeStaffNoApptTodayTitle,
            subtitle: context.l10n.homeStaffFreeDay,
            ctaLabel: context.l10n.commonRetry,
            onCta: _noop,
          );
        }
        final next = upcoming.first;
        final rest = upcoming.skip(1).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            StaffFeaturedCard(
              booking: next,
              onConfirmArrival: () => ref
                  .read(bookingActionNotifierProvider.notifier)
                  .markInProgress(next.id!)
                  .catchError((_) {}),
            ),
            if (rest.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeStaffLaterToday,
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final b in rest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: BookingListCard(booking: b),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AgendaTab extends ConsumerStatefulWidget {
  const _AgendaTab({required this.staffId});

  final String staffId;

  @override
  ConsumerState<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends ConsumerState<_AgendaTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(
      practitionerBookingsProvider((widget.staffId, _selectedDate)),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  ),
                ),
              ),
              Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: AppTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _selectedDate = _selectedDate.add(
                    const Duration(days: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: KynzaSkeleton(height: 56),
              ),
            ),
            error: (_, __) => KynzaErrorState(
              message: context.l10n.homeOwnerCalendarError,
              onRetry: () => ref.invalidate(
                practitionerBookingsProvider((widget.staffId, _selectedDate)),
              ),
            ),
            data: (bookings) {
              if (bookings.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: context.l10n.homeOwnerCalendarEmptyTitle,
                  subtitle: context.l10n.homeStaffNothingScheduled,
                  ctaLabel: context.l10n.commonToday,
                  onCta: _noop,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: bookings.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: BookingListCard(booking: bookings[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final _myClientsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      staffId,
    ) async {
      final rows = await SupabaseService.from('bookings')
          .select('client_id, users:client_id(full_name, phone)')
          .eq('practitioner_id', staffId)
          .isFilter('deleted_at', null);

      final byClient = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final clientId = row['client_id'] as String;
        final user = row['users'] as Map<String, dynamic>?;
        byClient.putIfAbsent(
          clientId,
          () => {'fullName': user?['full_name'] ?? '', 'phone': user?['phone']},
        );
      }
      return byClient.values.toList();
    });

class _MyClientsTab extends ConsumerWidget {
  const _MyClientsTab({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_myClientsProvider(staffId));

    return clientsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 64),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: context.l10n.homeOwnerClientsError,
        onRetry: () => ref.invalidate(_myClientsProvider(staffId)),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.people_outline,
            title: context.l10n.homeOwnerClientsEmptyTitle,
            subtitle: context.l10n.homeOwnerClientsEmptySubtitle,
            ctaLabel: context.l10n.commonBack,
            onCta: _noop,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final c = clients[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: KynzaCard(
                child: Row(
                  children: [
                    KynzaAvatar(fullName: c['fullName'] as String? ?? ''),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(c['fullName'] as String? ?? context.l10n.homeOwnerClientFallbackName)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
