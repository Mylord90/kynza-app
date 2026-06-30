import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/auth_providers.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: context.l10n.navCalendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            label: context.l10n.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: context.l10n.navClients,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign_outlined),
            label: context.l10n.navMarketing,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
