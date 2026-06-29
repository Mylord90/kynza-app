import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/notification_log_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

const _kPageSize = 20;

class _NotifFilter {
  const _NotifFilter(this.value, this.label);
  final String value;
  final String label;
}

const _filters = [
  _NotifFilter('all', 'Tous'),
  _NotifFilter('booking', 'RDV'),
  _NotifFilter('loyalty', 'Fidélité'),
  _NotifFilter('marketing', 'Marketing'),
  _NotifFilter('system', 'Système'),
];

String _categoryFor(String eventType) {
  if (eventType.startsWith('booking_')) return 'booking';
  if (eventType.startsWith('loyalty_') || eventType.startsWith('referral_')) {
    return 'loyalty';
  }
  if (eventType.startsWith('promo_') || eventType.startsWith('marketing_')) {
    return 'marketing';
  }
  return 'system';
}

String _sectionFor(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return "Aujourd'hui";
  if (diff < 7) return 'Cette semaine';
  return 'Plus ancien';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Map<String, Timer> _pendingDeletes = {};
  String _filter = 'all';
  int _limit = _kPageSize;

  @override
  void dispose() {
    for (final timer in _pendingDeletes.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _swipeDelete(String notifId, String title) {
    setState(() {});
    _pendingDeletes[notifId] = Timer(const Duration(seconds: 3), () {
      ref
          .read(notificationNotifierProvider.notifier)
          .delete(notifId)
          .catchError((_) {});
      _pendingDeletes.remove(notifId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('« $title » supprimée.'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            _pendingDeletes[notifId]?.cancel();
            _pendingDeletes.remove(notifId);
            setState(() {});
          },
        ),
      ),
    );
  }

  List<Widget> _buildItems(List<NotificationLogModel> notifications) {
    final widgets = <Widget>[];
    String? lastSection;
    for (final notif in notifications) {
      final section = _sectionFor(notif.createdAt ?? DateTime.now());
      if (section != lastSection) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Text(section, style: AppTypography.bodySmall),
          ),
        );
        lastSection = section;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Dismissible(
            key: ValueKey(notif.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            onDismissed: (_) => _swipeDelete(notif.id!, notif.title),
            child: NotificationTile(
              notification: notif,
              // No generic booking-detail route exists yet in this app
              // (only the role-specific calendar tiles/sheets) — tapping
              // only acknowledges the alert rather than risk a dead
              // navigation (R04).
              onTap: () => ref
                  .read(notificationNotifierProvider.notifier)
                  .markRead(notif.id!)
                  .catchError((_) {}),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider(_limit));
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: profile == null
                ? null
                : () => ref
                      .read(notificationNotifierProvider.notifier)
                      .markAllRead(profile.id)
                      .catchError((_) {}),
            child: const Text(
              'Tout marquer lu',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.notificationSettings),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _filter == filter.value;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = filter.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        filter.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: selected
                              ? AppColors.background
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaNotificationItemSkeleton(),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger vos notifications.',
                onRetry: () => ref.invalidate(notificationsProvider(_limit)),
              ),
              data: (all) {
                final notifications = _filter == 'all'
                    ? all
                    : all
                          .where((n) => _categoryFor(n.eventType) == _filter)
                          .toList();
                if (notifications.isEmpty) {
                  return const KynzaEmptyState(
                    icon: Icons.notifications_none,
                    title: 'Aucune notification',
                    subtitle: 'Revenez bientôt — vos alertes apparaîtront ici.',
                    ctaLabel: 'Retour',
                    onCta: _noop,
                  );
                }
                final canLoadMore = _filter == 'all' && all.length >= _limit;
                final items = _buildItems(notifications);
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(notificationsProvider(_limit)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: items.length + (canLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _limit += _kPageSize),
                              child: const Text('Charger plus'),
                            ),
                          ),
                        );
                      }
                      return items[index];
                    },
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

void _noop() {}
