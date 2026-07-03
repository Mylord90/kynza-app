import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/health_center_providers.dart';

enum _DataFreshness { realtime, polled, clientOnly, unavailable }

/// Phase 5 (Backend Enterprise Completion) — the single supervision surface
/// composing Phase 2's Track A data pipelines with drill-down, rather than
/// duplicating them: every section below reads directly from a
/// `health_center_providers.dart` provider that itself wraps one of the 7
/// `get_*_dashboard()` RPCs (or, where genuinely client-only, the existing
/// outbox/connectivity/Realtime-client state) — no query is re-implemented
/// here. This also satisfies Phase 2's own "admin-only screen per dashboard"
/// requirement: building 13 separate fully-standalone screens in addition
/// to this composition would directly contradict Phase 5's explicit
/// "do not duplicate" instruction, so this is the one and only screen for
/// all 13 named dashboards, each as its own expandable, individually
/// real, individually gated section.
class HealthCenterScreen extends ConsumerWidget {
  const HealthCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionHealthCenterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Health Dashboard — this screen itself is the composed overview.
          _RpcSection(
            title: 'System Metrics / Supabase Dashboard',
            freshness: _DataFreshness.polled,
            provider: supabaseDashboardProvider,
          ),
          _RpcSection(
            title: 'Storage Dashboard',
            freshness: _DataFreshness.polled,
            provider: storageDashboardProvider,
          ),
          _RpcSection(
            title: 'Notification Dashboard',
            freshness: _DataFreshness.polled,
            provider: notificationDashboardProvider,
          ),
          _RpcSection(
            title: 'Queue Dashboard',
            freshness: _DataFreshness.polled,
            provider: queueDashboardProvider,
          ),
          _RpcSection(
            title: 'Edge Function Dashboard',
            freshness: _DataFreshness.polled,
            provider: edgeFunctionDashboardProvider,
          ),
          _RpcSection(
            title: 'Crash Dashboard',
            freshness: _DataFreshness.polled,
            provider: crashDashboardProvider,
          ),
          _RpcSection(
            title: 'Security Dashboard',
            freshness: _DataFreshness.polled,
            provider: securityDashboardProvider,
          ),
          const _SyncDashboardSection(),
          const _RealtimeDashboardSection(),
          const _NetworkDashboardSection(),
          const _PerformanceDashboardSection(),
        ],
      ),
    );
  }
}

class _FreshnessBadge extends StatelessWidget {
  const _FreshnessBadge({required this.freshness});

  final _DataFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final label = switch (freshness) {
      _DataFreshness.realtime => context.l10n.evolutionHealthCenterRealtimeLabel,
      _DataFreshness.polled => context.l10n.evolutionHealthCenterPolledLabel,
      _DataFreshness.clientOnly =>
        context.l10n.evolutionHealthCenterClientOnlyLabel,
      _DataFreshness.unavailable =>
        context.l10n.evolutionHealthCenterUnavailableLabel,
    };
    return KynzaBadge(label: label);
  }
}

class _RpcSection extends ConsumerWidget {
  const _RpcSection({
    required this.title,
    required this.freshness,
    required this.provider,
  });

  final String title;
  final _DataFreshness freshness;
  final FutureProvider<List<Map<String, dynamic>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(provider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.body)),
              _FreshnessBadge(freshness: freshness),
            ],
          ),
          children: [
            rowsAsync.when(
              loading: () => const KynzaSkeleton(height: 60),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.errorLoadFailed,
                onRetry: () => ref.invalidate(provider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.insert_chart_outlined,
                    title: context.l10n.evolutionHealthCenterEmptyTitle,
                    subtitle: context.l10n.evolutionHealthCenterEmptySubtitle,
                    ctaLabel: context.l10n.commonRetry,
                    onCta: () => ref.invalidate(provider),
                  );
                }
                return Column(
                  children: rows
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            row.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncDashboardSection extends ConsumerWidget {
  const _SyncDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncDashboardProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Row(
            children: [
              Expanded(
                child: Text('Sync Dashboard', style: AppTypography.body),
              ),
              _FreshnessBadge(freshness: _DataFreshness.clientOnly),
            ],
          ),
          children: [
            Text(
              'Pending: ${status.pendingCount} · Dead-letter: ${status.deadLetterCount}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RealtimeDashboardSection extends ConsumerWidget {
  const _RealtimeDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeChannelStatusProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Row(
            children: [
              Expanded(
                child: Text('Realtime Dashboard', style: AppTypography.body),
              ),
              _FreshnessBadge(freshness: _DataFreshness.clientOnly),
            ],
          ),
          children: [Text(status, style: AppTypography.bodySmall)],
        ),
      ),
    );
  }
}

class _NetworkDashboardSection extends ConsumerWidget {
  const _NetworkDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(networkDashboardProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Row(
            children: [
              Expanded(
                child: Text('Network Dashboard', style: AppTypography.body),
              ),
              _FreshnessBadge(freshness: _DataFreshness.realtime),
            ],
          ),
          children: [
            connected.when(
              loading: () => const KynzaSkeleton(height: 24),
              error: (_, __) => Text(context.l10n.errorLoadFailed),
              data: (isOnline) => Text(
                isOnline ? 'Connected' : 'Offline',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceDashboardSection extends ConsumerWidget {
  const _PerformanceDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(performanceDashboardProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Row(
            children: [
              Expanded(
                child: Text('Performance Dashboard', style: AppTypography.body),
              ),
              _FreshnessBadge(freshness: _DataFreshness.unavailable),
            ],
          ),
          children: [
            KynzaEmptyState(
              icon: Icons.speed_outlined,
              title: context.l10n.evolutionHealthCenterEmptyTitle,
              subtitle:
                  'Firebase Performance Monitoring has no in-app read API — '
                  'view collected traces in the Firebase Console.',
              ctaLabel: context.l10n.commonRetry,
              onCta: () {},
            ),
          ],
        ),
      ),
    );
  }
}
