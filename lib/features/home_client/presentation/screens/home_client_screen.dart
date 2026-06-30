import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/presentation/screens/salon_detail_screen.dart';
import '../../../booking/presentation/screens/salon_discovery_screen.dart';
import '../../../loyalty/presentation/screens/client_loyalty_screen.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../notifications/presentation/widgets/unread_count_badge.dart';
import 'client_bookings_screen.dart';
import 'client_profile_screen.dart';

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
          const UnreadCountBadge(),
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
              2 => const ClientBookingsScreen(),
              3 => const ClientLoyaltyScreen(),
              _ => const ClientProfileScreen(),
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: context.l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            label: context.l10n.homeClientNavExplorer,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_outlined),
            label: context.l10n.homeClientNavMyBookings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.star_outline),
            label: context.l10n.homeClientNavMyLoyalties,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }

  String _titleFor(int index, String? firstName) => switch (index) {
    0 => context.l10n.homeClientGreeting(firstName ?? ''),
    1 => context.l10n.homeClientNavExplorer,
    2 => context.l10n.homeClientNavMyBookings,
    3 => context.l10n.homeClientNavMyLoyalties,
    _ => context.l10n.navProfile,
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
        message: context.l10n.homeClientCannotLoadSalons,
        onRetry: () => ref.invalidate(discoverSalonsProvider),
      ),
      data: (salons) {
        if (salons.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.storefront_outlined,
            title: context.l10n.homeClientDiscoverTitle,
            subtitle: context.l10n.homeClientNoSalonsSubtitle,
            ctaLabel: context.l10n.commonRefresh,
            onCta: _noop,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(context.l10n.homeClientSalonsNearYou, style: AppTypography.h3),
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
