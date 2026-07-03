import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/freemium_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/navigation/kynza_bottom_nav.dart';
import '../../../../shared/navigation/kynza_nav_item.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/walkin_booking_sheet.dart';
import '../../../marketing/presentation/screens/marketing_dashboard_screen.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../salon/presentation/screens/salon_creation_wizard_screen.dart';
import '../../../notifications/presentation/widgets/unread_count_badge.dart';
import '../../../dashboard/presentation/screens/advanced_dashboard_screen.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
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
              tooltip: context.l10n.homeOwnerConfidentialModeTooltip,
              onPressed: () =>
                  ref.read(confidentialModeProvider.notifier).toggle(),
            ),
          if (_tabIndex == 3)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: context.l10n.homeOwnerShareTooltip,
              onPressed: () => context.go(RouteNames.ownerShare),
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: context.l10n.homeOwnerScanLoyaltyTooltip,
            onPressed: () => context.push(RouteNames.ownerLoyaltyScan),
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
              1 => AdvancedDashboardTabs(salonId: salon.id),
              2 => _ClientsTab(salonId: salon.id),
              3 => MarketingDashboardBody(salonId: salon.id),
              _ => const _ProfileTab(),
            },
      bottomNavigationBar: KynzaBottomNav(
        currentIndex: _tabIndex,
        onItemTapped: (index) => setState(() => _tabIndex = index),
        items: [
          KynzaNavItem(
            icon: PhosphorIconsRegular.calendarCheck,
            activeIcon: PhosphorIconsBold.calendarCheck,
            label: context.l10n.navCalendar,
          ),
          KynzaNavItem(
            icon: PhosphorIconsRegular.chartBarHorizontal,
            activeIcon: PhosphorIconsBold.chartBarHorizontal,
            label: context.l10n.navDashboard,
          ),
          KynzaNavItem(
            icon: PhosphorIconsRegular.users,
            activeIcon: PhosphorIconsBold.users,
            label: context.l10n.navClients,
          ),
          KynzaNavItem(
            icon: PhosphorIconsRegular.megaphone,
            activeIcon: PhosphorIconsBold.megaphone,
            label: context.l10n.navMarketing,
          ),
          KynzaNavItem(
            icon: PhosphorIconsRegular.userCircle,
            activeIcon: PhosphorIconsBold.userCircle,
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) => switch (index) {
    0 => context.l10n.navCalendar,
    1 => '📊 ${context.l10n.homeOwnerDashboardTitle}',
    2 => context.l10n.navClients,
    3 => context.l10n.navMarketing,
    _ => context.l10n.navProfile,
  };
}

class _NoSalonEmptyState extends StatelessWidget {
  const _NoSalonEmptyState();

  @override
  Widget build(BuildContext context) {
    return KynzaEmptyState(
      icon: Icons.store_outlined,
      title: context.l10n.homeOwnerNoSalonTitle,
      subtitle: context.l10n.homeOwnerNoSalonSubtitle,
      ctaLabel: context.l10n.homeOwnerNoSalonCta,
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
            showFreemiumLimitModal(
              context,
              onUpgrade: () => context.push(RouteNames.ownerSubscription),
            );
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
          if (salon != null)
            FreemiumBanner(
              onUpgrade: () => context.push(RouteNames.ownerSubscription),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: context.l10n.commonPrevious,
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
                  tooltip: context.l10n.commonNext,
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
                message: context.l10n.homeOwnerCalendarError,
                onRetry: () => ref.invalidate(
                  salonBookingsProvider((widget.salonId, _selectedDate)),
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: context.l10n.homeOwnerCalendarEmptyTitle,
                    subtitle: context.l10n.homeOwnerCalendarEmptySubtitle,
                    ctaLabel: context.l10n.homeOwnerCalendarEmptyCta,
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
        message: context.l10n.homeOwnerClientsError,
        onRetry: () => ref.invalidate(_salonClientsProvider(salonId)),
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
                            client['fullName'] as String? ??
                                context.l10n.homeOwnerClientFallbackName,
                            style: AppTypography.h3,
                          ),
                          if (client['phone'] != null)
                            Text(client['phone'] as String),
                        ],
                      ),
                    ),
                    Text(
                      context.l10n.homeOwnerClientRdvCount(
                        client['count'] as int,
                      ),
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
        KynzaCard(
          onTap: () => context.go(RouteNames.ownerReviews),
          child: Row(
            children: [
              const Icon(Icons.star_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.homeOwnerProfileMyReviews,
                  style: AppTypography.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaCard(
          onTap: () => context.push(RouteNames.ownerAuditLogs),
          child: Row(
            children: [
              const Icon(Icons.history_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.homeOwnerProfileActivityLog,
                  style: AppTypography.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaCard(
          onTap: () => context.push(RouteNames.ownerSettings),
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.homeOwnerProfileSettings,
                  style: AppTypography.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaCard(
          onTap: () => context.push(RouteNames.ownerBilling),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.homeOwnerProfileSubscription,
                  style: AppTypography.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaCard(
          onTap: () => context.push(RouteNames.ownerLanguage),
          child: Row(
            children: [
              const Icon(Icons.language, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.homeOwnerProfileLanguage,
                  style: AppTypography.h3,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KynzaButton(
          label: context.l10n.authLogout,
          variant: KynzaButtonVariant.destructive,
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
