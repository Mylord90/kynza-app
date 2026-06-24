import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/screens/salon_detail_screen.dart';
import '../../../booking/presentation/screens/salon_discovery_screen.dart';
import '../../../booking/presentation/widgets/booking_list_card.dart';
import '../../../salon/application/providers/salon_providers.dart';

class HomeClientScreen extends ConsumerStatefulWidget {
  const HomeClientScreen({super.key});

  @override
  ConsumerState<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends ConsumerState<HomeClientScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_titleFor(_tabIndex, profile?.firstName)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: KynzaAvatar(
              fullName: profile?.fullName ?? '',
              avatarUrl: profile?.avatarUrl,
              size: AvatarSize.sm,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: switch (_tabIndex) {
              0 => const _HomeTab(),
              1 => const SalonDiscoveryScreen(),
              2 => const _AppointmentsTab(),
              _ => const _ProfileTab(),
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Mes RDV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _titleFor(int index, String? firstName) => switch (index) {
    0 => 'Bonjour ${firstName ?? ''} 👋',
    1 => 'Explorer',
    2 => 'Mes RDV',
    _ => 'Profil',
  };
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonsAsync = ref.watch(discoverSalonsProvider);

    return salonsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 120),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: 'Impossible de charger les salons.',
        onRetry: () => ref.invalidate(discoverSalonsProvider),
      ),
      data: (salons) {
        if (salons.isEmpty) {
          return const KynzaEmptyState(
            icon: Icons.storefront_outlined,
            title: 'Découvrez les salons',
            subtitle: 'Aucun salon disponible pour le moment.',
            ctaLabel: 'Actualiser',
            onCta: _noop,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('Salons près de vous', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            for (final salon in salons.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: KynzaCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SalonDetailScreen(salonId: salon.id),
                    ),
                  ),
                  child: Row(
                    children: [
                      KynzaAvatar(
                        fullName: salon.name,
                        avatarUrl: salon.logoUrl,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(salon.name, style: AppTypography.h3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void _noop() {}

class _AppointmentsTab extends ConsumerStatefulWidget {
  const _AppointmentsTab();

  @override
  ConsumerState<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends ConsumerState<_AppointmentsTab> {
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(clientBookingsProvider(profile.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('À venir')),
              ButtonSegment(value: false, label: Text('Passés')),
            ],
            selected: {_showUpcoming},
            onSelectionChanged: (s) => setState(() => _showUpcoming = s.first),
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: KynzaSkeleton(height: 72),
              ),
            ),
            error: (_, __) => KynzaErrorState(
              message: 'Impossible de charger vos RDV.',
              onRetry: () => ref.invalidate(clientBookingsProvider(profile.id)),
            ),
            data: (bookings) {
              final now = DateTime.now();
              final filtered = bookings
                  .where(
                    (b) => _showUpcoming
                        ? b.startTime.isAfter(now)
                        : b.startTime.isBefore(now),
                  )
                  .toList();
              if (filtered.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'Aucun RDV',
                  subtitle: _showUpcoming
                      ? 'Réservez votre prochain rendez-vous beauté.'
                      : "Vous n'avez pas encore d'historique.",
                  ctaLabel: 'Réserver maintenant',
                  onCta: _noop,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: filtered.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: BookingListCard(booking: filtered[index]),
                ),
              );
            },
          ),
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
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.fullName ?? '', style: AppTypography.h3),
                    if (profile?.phone != null) Text(profile!.phone!),
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
