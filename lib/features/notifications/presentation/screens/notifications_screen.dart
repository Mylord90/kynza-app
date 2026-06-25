import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Map<String, Timer> _pendingDeletes = {};

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

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
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
          Expanded(
            child: notificationsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 72),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger vos notifications.',
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const KynzaEmptyState(
                    icon: Icons.notifications_none,
                    title: 'Aucune notification',
                    subtitle: 'Revenez bientôt — vos alertes apparaîtront ici.',
                    ctaLabel: 'Retour',
                    onCta: _noop,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notificationsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Dismissible(
                          key: ValueKey(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(
                              right: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.md,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                          onDismissed: (_) =>
                              _swipeDelete(notif.id!, notif.title),
                          child: NotificationTile(
                            notification: notif,
                            // No generic booking-detail route exists yet in
                            // this app (only the role-specific calendar
                            // tiles/sheets) — tapping only acknowledges the
                            // alert rather than risk a dead navigation (R04).
                            onTap: () => ref
                                .read(notificationNotifierProvider.notifier)
                                .markRead(notif.id!)
                                .catchError((_) {}),
                          ),
                        ),
                      );
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
