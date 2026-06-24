import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/booking_list_card.dart';
import '../../../staff/application/providers/staff_providers.dart';
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
      appBar: AppBar(title: Text(_titleFor(_tabIndex))),
      body: staffAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 200),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger votre profil.',
          onRetry: () => ref.invalidate(myStaffProfileProvider),
        ),
        data: (staff) {
          if (staff == null) {
            return const KynzaEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profil non lié',
              subtitle:
                  "Votre compte n'est pas encore associé à une équipe. "
                  'Demandez une invitation à votre Owner.',
              ctaLabel: 'Actualiser',
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
                  _ => _PerfTab(staffId: staff.id!),
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            label: "Aujourd'hui",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Mes Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Ma Perf',
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) => switch (index) {
    0 => "Aujourd'hui",
    1 => 'Agenda',
    2 => 'Mes Clients',
    _ => 'Ma Perf',
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
        message: 'Impossible de charger votre agenda.',
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
          return const KynzaEmptyState(
            icon: Icons.event_available_outlined,
            title: "Aucun RDV aujourd'hui",
            subtitle: 'Profitez de votre journée libre !',
            ctaLabel: 'Actualiser',
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
                  .markInProgress(next.id!),
            ),
            if (rest.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plus tard aujourd\'hui',
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
              message: 'Impossible de charger ce jour.',
              onRetry: () => ref.invalidate(
                practitionerBookingsProvider((widget.staffId, _selectedDate)),
              ),
            ),
            data: (bookings) {
              if (bookings.isEmpty) {
                return const KynzaEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Aucun RDV ce jour',
                  subtitle: 'Rien de prévu pour cette date.',
                  ctaLabel: "Aujourd'hui",
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
        message: 'Impossible de charger vos clients.',
        onRetry: () => ref.invalidate(_myClientsProvider(staffId)),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return const KynzaEmptyState(
            icon: Icons.people_outline,
            title: 'Aucun client encore',
            subtitle: 'Vos clients apparaîtront ici après vos premiers RDV.',
            ctaLabel: 'Retour',
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
                    Expanded(child: Text(c['fullName'] as String? ?? 'Client')),
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

class _PerfTab extends ConsumerWidget {
  const _PerfTab({required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(_staffWeekRankProvider(staffId));
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        FutureBuilder<List<BookingModel>>(
          future: ref
              .read(bookingRepositoryProvider)
              .getPractitionerBookingsInRange(
                staffId,
                weekStart,
                weekStart.add(const Duration(days: 7)),
              ),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? [];
            final completed = bookings
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
      ],
    );
  }

  String _ordinalSuffix(int n) => n == 1 ? 'er' : 'ème';
}
