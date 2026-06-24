import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/freemium_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/walkin_booking_sheet.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../salon/presentation/screens/salon_creation_wizard_screen.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../../services/presentation/screens/services_list_screen.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../../staff/presentation/screens/staff_invite_screen.dart';
import '../../../notifications/presentation/widgets/unread_count_badge.dart';
import '../../../dashboard/application/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/kynza_kpi_card.dart';
import '../../../dashboard/presentation/widgets/kynza_period_selector.dart';
import '../../../dashboard/presentation/widgets/kynza_simple_bar_chart.dart';
import '../../../dashboard/presentation/widgets/kynza_top_services_list.dart';
import '../../../dashboard/presentation/widgets/kynza_top_staff_row.dart';
import '../../../../core/enums/user_role.dart';
import '../widgets/booking_detail_sheet.dart';
import '../widgets/booking_tile.dart';

class HomeOwnerScreen extends ConsumerStatefulWidget {
  const HomeOwnerScreen({super.key});

  @override
  ConsumerState<HomeOwnerScreen> createState() => _HomeOwnerScreenState();
}

class _HomeOwnerScreenState extends ConsumerState<HomeOwnerScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titleFor(_tabIndex)),
        actions: [
          if (_tabIndex == 1)
            IconButton(
              icon: Icon(
                ref.watch(confidentialModeProvider)
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () =>
                  ref.read(confidentialModeProvider.notifier).toggle(),
            ),
          const UnreadCountBadge(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: KynzaAvatar(
              fullName: profile?.fullName ?? '',
              avatarUrl: profile?.avatarUrl,
              size: AvatarSize.sm,
              isOwner: true,
            ),
          ),
        ],
      ),
      body: salon == null
          ? const _NoSalonEmptyState()
          : switch (_tabIndex) {
              0 => _CalendarTab(salonId: salon.id),
              1 => _DashboardTab(salonId: salon.id),
              2 => _ClientsTab(salonId: salon.id),
              3 => _MarketingTab(salonId: salon.id),
              _ => const _ProfileTab(),
            },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Marketing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) => switch (index) {
    0 => 'Calendrier',
    1 => '📊 Dashboard KYNZA',
    2 => 'Clients',
    3 => 'Marketing',
    _ => 'Profil',
  };
}

class _NoSalonEmptyState extends StatelessWidget {
  const _NoSalonEmptyState();

  @override
  Widget build(BuildContext context) {
    return KynzaEmptyState(
      icon: Icons.store_outlined,
      title: 'Créez votre salon',
      subtitle:
          'Configurez votre salon pour commencer à recevoir des réservations.',
      ctaLabel: 'Créer mon salon →',
      onCta: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SalonCreationWizardScreen()),
      ),
    );
  }
}

class _CalendarTab extends ConsumerStatefulWidget {
  const _CalendarTab({required this.salonId});

  final String salonId;

  @override
  ConsumerState<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<_CalendarTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(
      salonBookingsProvider((widget.salonId, _selectedDate)),
    );
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          if (salon == null) return;
          if (!FreemiumService.canCreateBooking(salon)) {
            showFreemiumLimitModal(context, onUpgrade: () {});
            return;
          }
          showKynzaBottomSheet(
            context,
            builder: (_) => WalkInBookingSheet(salonId: salon.id),
          );
        },
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          if (salon != null) FreemiumBanner(onUpgrade: () {}),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 56),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger le planning.',
                onRetry: () => ref.invalidate(
                  salonBookingsProvider((widget.salonId, _selectedDate)),
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'Aucun RDV ce jour',
                    subtitle: 'Votre planning est libre.',
                    ctaLabel: "Aujourd'hui",
                    onCta: () => setState(() => _selectedDate = DateTime.now()),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) => BookingTile(
                    booking: bookings[index],
                    onTap: () => showKynzaBottomSheet(
                      context,
                      builder: (_) =>
                          BookingDetailSheet(booking: bookings[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider(salonId));
    final servicesAsync = ref.watch(salonServicesProvider(salonId));
    final topServicesAsync = ref.watch(topServicesProvider(salonId));
    final topStaffAsync = ref.watch(topStaffProvider(salonId));
    final staffAsync = ref.watch(salonStaffProvider(salonId));
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isOwner = profile?.role == UserRole.owner;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardSummaryProvider(salonId)),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const KynzaOfflineBanner(),
          const SizedBox(height: AppSpacing.sm),
          KynzaPeriodSelector(
            selected: period,
            onChanged: (r) =>
                ref.read(selectedPeriodProvider.notifier).state = r,
          ),
          const SizedBox(height: AppSpacing.lg),
          // SECTION 1 — KPI Grid 2x2
          summaryAsync.when(
            loading: () => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: const [
                KynzaSkeleton(height: 90),
                KynzaSkeleton(height: 90),
                KynzaSkeleton(height: 90),
                KynzaSkeleton(height: 90),
              ],
            ),
            error: (_, __) => KynzaErrorState(
              message: 'Impossible de charger le dashboard.',
              onRetry: () => ref.invalidate(dashboardSummaryProvider(salonId)),
            ),
            data: (summary) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: [
                KynzaKpiCard(
                  label: 'Revenu',
                  amountBif: summary.revenueBif,
                  trendPct: summary.revenueTrendPct,
                  icon: Icons.payments_outlined,
                ),
                KynzaKpiCard(
                  label: 'Réservations',
                  value: '${summary.bookingsTotal}',
                  trendPct: summary.bookingsTrendPct,
                  icon: Icons.event_available_outlined,
                ),
                KynzaKpiCard(
                  label: 'Taux remplissage',
                  value: '${summary.occupancyRate.round()}%',
                  icon: Icons.donut_large_outlined,
                ),
                KynzaKpiCard(
                  label: 'Taux no-show',
                  value: '${summary.noShowRate.round()}%',
                  icon: Icons.event_busy_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // SECTION 2 — Revenue chart
          summaryAsync.when(
            loading: () => const KynzaSkeleton(height: 180),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => KynzaSimpleBarChart(
              title: 'Évolution du CA',
              bars: [
                for (final kpi in summary.dailySeries)
                  BarData(label: '${kpi.day.day}', value: kpi.revenueBif),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // SECTION 3 — Top services
          topServicesAsync.when(
            loading: () => const KynzaSkeleton(height: 92),
            error: (_, __) => const SizedBox.shrink(),
            data: (services) => services.isEmpty
                ? KynzaEmptyState(
                    icon: Icons.spa_outlined,
                    title: 'Aucun service',
                    subtitle:
                        'Ajoutez vos prestations pour suivre leur succès.',
                    ctaLabel: 'Ajouter un service',
                    onCta: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServicesListScreen(),
                      ),
                    ),
                  )
                : KynzaTopServicesList(services: services),
          ),
          const SizedBox(height: AppSpacing.xl),
          // SECTION 4 — Top staff (owner only)
          if (isOwner)
            topStaffAsync.when(
              loading: () => const KynzaSkeleton(height: 96),
              error: (_, __) => const SizedBox.shrink(),
              data: (staff) => staff.isEmpty
                  ? KynzaEmptyState(
                      icon: Icons.people_outline,
                      title: 'Aucun staff',
                      subtitle:
                          'Invitez votre équipe pour suivre leurs performances.',
                      ctaLabel: 'Inviter votre équipe',
                      onCta: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffInviteScreen(salonId: salonId),
                        ),
                      ),
                    )
                  : KynzaTopStaffRow(staff: staff, isOwner: isOwner),
            ),
          const SizedBox(height: AppSpacing.xl),
          // SECTION 5 — Quick actions
          servicesAsync.maybeWhen(
            data: (services) => staffAsync.maybeWhen(
              data: (staff) => _QuickActionsRow(
                salonId: salonId,
                hasServices: services.isNotEmpty,
                hasStaff: staff.isNotEmpty,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.salonId,
    required this.hasServices,
    required this.hasStaff,
  });

  final String salonId;
  final bool hasServices;
  final bool hasStaff;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_outline,
            label: 'Nouveau RDV',
            onTap: () => showKynzaBottomSheet(
              context,
              builder: (_) => WalkInBookingSheet(salonId: salonId),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.spa_outlined,
            label: hasServices ? 'Services' : 'Ajouter service',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServicesListScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.person_add_outlined,
            label: hasStaff ? 'Équipe' : 'Inviter staff',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StaffInviteScreen(salonId: salonId),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

final _salonClientsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      salonId,
    ) async {
      final rows = await SupabaseService.from('bookings')
          .select('client_id, users:client_id(full_name, phone)')
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null);

      final byClient = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final clientId = row['client_id'] as String;
        final user = row['users'] as Map<String, dynamic>?;
        final existing = byClient[clientId];
        if (existing == null) {
          byClient[clientId] = {
            'id': clientId,
            'fullName': user?['full_name'] ?? '',
            'phone': user?['phone'],
            'count': 1,
          };
        } else {
          existing['count'] = (existing['count'] as int) + 1;
        }
      }
      return byClient.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    });

class _ClientsTab extends ConsumerWidget {
  const _ClientsTab({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_salonClientsProvider(salonId));

    return clientsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 64),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: 'Impossible de charger vos clients.',
        onRetry: () => ref.invalidate(_salonClientsProvider(salonId)),
      ),
      data: (clients) {
        if (clients.isEmpty) {
          return const KynzaEmptyState(
            icon: Icons.people_outline,
            title: 'Aucun client encore',
            subtitle:
                'Vos clients apparaîtront ici après leur première réservation.',
            ctaLabel: 'Retour',
            onCta: _noop,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: KynzaCard(
                child: Row(
                  children: [
                    KynzaAvatar(fullName: client['fullName'] as String? ?? ''),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['fullName'] as String? ?? 'Client',
                            style: AppTypography.h3,
                          ),
                          if (client['phone'] != null)
                            Text(client['phone'] as String),
                        ],
                      ),
                    ),
                    Text(
                      '${client['count']} RDV',
                      style: AppTypography.bodySmall,
                    ),
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

void _noop() {}

class _MarketingTab extends ConsumerWidget {
  const _MarketingTab({required this.salonId});

  final String salonId;

  Future<void> _fillMyDay(BuildContext context, WidgetRef ref) async {
    try {
      final allowed = await SupabaseService.client.rpc(
        'check_and_increment_promo_quota',
        params: {'p_salon_id': salonId},
      );
      if (allowed != true) {
        if (context.mounted) {
          showKynzaToast(
            context,
            message: 'Limite de 2 promotions par semaine atteinte.',
            level: ToastLevel.warning,
          );
        }
        return;
      }
      await Share.share(
        '🔥 Des créneaux se sont libérés aujourd\'hui ! Réservez vite via KYNZA.',
      );
    } catch (_) {
      if (context.mounted) {
        showKynzaToast(
          context,
          message: "Échec de l'envoi.",
          level: ToastLevel.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('Remplir ma journée', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Des créneaux libres aujourd\'hui ou demain ? Partagez une promotion '
          'à vos contacts personnels (max 2 par semaine).',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaButton(
          label: 'Partager une promo →',
          onPressed: () => _fillMyDay(context, ref),
        ),
      ],
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        KynzaCard(
          child: Row(
            children: [
              KynzaAvatar(
                fullName: profile?.fullName ?? '',
                avatarUrl: profile?.avatarUrl,
                size: AvatarSize.lg,
                isOwner: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.fullName ?? '', style: AppTypography.h3),
                    if (salon != null) Text(salon.name),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaButton(
          label: 'Se déconnecter',
          variant: KynzaButtonVariant.destructive,
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
