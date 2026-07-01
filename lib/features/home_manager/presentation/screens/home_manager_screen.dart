import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../shared/navigation/kynza_bottom_nav.dart';
import '../../../../shared/navigation/kynza_nav_item.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class HomeManagerScreen extends ConsumerStatefulWidget {
  const HomeManagerScreen({super.key});

  @override
  ConsumerState<HomeManagerScreen> createState() => _HomeManagerScreenState();
}

class _HomeManagerScreenState extends ConsumerState<HomeManagerScreen> {
  int _tabIndex = 1;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('📊 ${context.l10n.homeManagerDashboardTitle}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
            child: KynzaEmptyState(
              icon: Icons.dashboard_outlined,
              title: context.l10n.homeManagerDashboardTitle,
              subtitle: context.l10n.homeManagerDashboardBody,
              ctaLabel: context.l10n.homeManagerDashboardCta,
              onCta: () {},
            ),
          ),
        ],
      ),
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
}
