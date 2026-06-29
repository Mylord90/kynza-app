import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/date_range.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/analytics/churn_risk_model.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/staff_monthly_performance_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../journey/presentation/widgets/journey_progress_card.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../../services/presentation/screens/services_list_screen.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../../staff/presentation/screens/staff_invite_screen.dart';
import '../../application/providers/dashboard_providers.dart';
import '../widgets/kynza_bar_chart_fl.dart';
import '../widgets/kynza_cohort_table.dart';
import '../widgets/kynza_kpi_card.dart';
import '../widgets/kynza_line_chart.dart';
import '../widgets/kynza_period_selector.dart';
import '../widgets/kynza_pie_chart.dart';
import '../widgets/kynza_simple_bar_chart.dart';
import '../widgets/kynza_top_services_list.dart';
import '../widgets/kynza_top_staff_row.dart';

const _weekdayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Standalone Scaffold for the `/owner/analytics[...]` routes — wraps the
/// same [AdvancedDashboardTabs] embedded inline as the owner's bottom-nav
/// Dashboard tab (home_owner_screen.dart), so there's one tab
/// implementation, not two.
class AdvancedDashboardScreen extends StatelessWidget {
  const AdvancedDashboardScreen({
    super.key,
    required this.salonId,
    this.initialIndex = 0,
  });

  final String salonId;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('📊 Dashboard KYNZA')),
      body: AdvancedDashboardTabs(salonId: salonId, initialIndex: initialIndex),
    );
  }
}

class AdvancedDashboardTabs extends StatefulWidget {
  const AdvancedDashboardTabs({
    super.key,
    required this.salonId,
    this.initialIndex = 0,
  });

  final String salonId;
  final int initialIndex;

  @override
  State<AdvancedDashboardTabs> createState() => _AdvancedDashboardTabsState();
}

class _AdvancedDashboardTabsState extends State<AdvancedDashboardTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Vue d'ensemble"),
            Tab(text: 'Clients'),
            Tab(text: 'Équipe'),
            Tab(text: 'Prévisions'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              _OverviewTab(salonId: widget.salonId),
              _ClientsAnalyticsTab(salonId: widget.salonId),
              _TeamAnalyticsTab(salonId: widget.salonId),
              _ForecastTab(salonId: widget.salonId),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.salonId});

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
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardSummaryProvider(salonId)),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const KynzaOfflineBanner(),
          const SizedBox(height: AppSpacing.sm),
          JourneyProgressCard(salonId: salonId),
          FreemiumBanner(
            onUpgrade: () => context.push(RouteNames.ownerSubscription),
          ),
          KynzaPeriodSelector(
            selected: period,
            onChanged: (r) =>
                ref.read(selectedPeriodProvider.notifier).state = r,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (salon != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Exporter PDF',
                  style: TextStyle(color: AppColors.primary),
                ),
                onPressed: () => _exportPdf(
                  salon: salon,
                  summary: summaryAsync.valueOrNull,
                  topServices: topServicesAsync.valueOrNull ?? const [],
                  topStaff: isOwner
                      ? (topStaffAsync.valueOrNull ?? const [])
                      : const [],
                  range: period,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
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

  Future<void> _exportPdf({
    required SalonFullModel salon,
    required DashboardSummary? summary,
    required List<TopServiceModel> topServices,
    required List<TopStaffModel> topStaff,
    required DateRange range,
  }) async {
    if (summary == null) return;
    final bytes = await ExportService.generateRevenueReport(
      salon: salon,
      summary: summary,
      range: range,
      topServices: topServices,
      topStaff: topStaff,
    );
    await ExportService.sharePdf(bytes, 'kynza-rapport-${salon.id}.pdf');
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

class _ClientsAnalyticsTab extends ConsumerWidget {
  const _ClientsAnalyticsTab({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newVsReturningAsync = ref.watch(newVsReturningProvider(salonId));
    final churnAsync = ref.watch(churnRisksProvider(salonId));
    final topClientsAsync = ref.watch(topClientsProvider(salonId));
    final cohortAsync = ref.watch(cohortRetentionProvider(salonId));
    final clientLtvAsync = ref.watch(clientLtvProvider(salonId));
    final salon = ref.watch(salonByIdProvider(salonId)).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(
              Icons.table_chart_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            label: const Text(
              'Exporter clients (CSV)',
              style: TextStyle(color: AppColors.primary),
            ),
            onPressed: clientLtvAsync.valueOrNull == null
                ? null
                : () => ShareService.shareCsv(
                    CsvExporter.clientsToCsv(clientLtvAsync.valueOrNull!),
                    'kynza-clients-$salonId.csv',
                  ),
          ),
        ),
        const Text('Nouveaux vs Récurrents', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        newVsReturningAsync.when(
          loading: () => const KynzaSkeleton(height: 180),
          error: (_, __) => const SizedBox.shrink(),
          data: (counts) => KynzaPieChart(
            slices: [
              KynzaPieSlice(
                label: 'Nouveaux',
                value: (counts['new'] ?? 0).toDouble(),
                color: AppColors.primary,
              ),
              KynzaPieSlice(
                label: 'Récurrents',
                value: (counts['returning'] ?? 0).toDouble(),
                color: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Clients à risque', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        churnAsync.when(
          loading: () => const KynzaSkeleton(height: 64, count: 3),
          error: (_, __) => const SizedBox.shrink(),
          data: (risks) => risks.isEmpty
              ? const Text(
                  'Aucun client à risque pour le moment.',
                  style: AppTypography.bodySmall,
                )
              : Column(
                  children: [
                    for (final level in ['high', 'medium', 'low'])
                      _ChurnRiskSection(
                        level: level,
                        risks: risks
                            .where((r) => r.riskLevel == level)
                            .toList(),
                        salonName: salon?.name ?? '',
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Meilleurs clients', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        topClientsAsync.when(
          loading: () => const KynzaSkeleton(height: 56, count: 5),
          error: (_, __) => const SizedBox.shrink(),
          data: (clients) => clients.isEmpty
              ? const Text(
                  'Pas encore de clients.',
                  style: AppTypography.bodySmall,
                )
              : Column(
                  children: [
                    for (var i = 0; i < clients.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: KynzaCard(
                          child: Row(
                            children: [
                              Text('#${i + 1}', style: AppTypography.h3),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  clients[i].clientName,
                                  style: AppTypography.body,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  KynzaAmountWidget(
                                    amountBif: clients[i].totalSpentBif,
                                    style: AppTypography.bodySmall,
                                  ),
                                  Text(
                                    '${clients[i].visitCount} visites',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Rétention par cohorte', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        cohortAsync.when(
          loading: () => const KynzaSkeleton(height: 160),
          error: (_, __) => const SizedBox.shrink(),
          data: (rows) => KynzaCohortTable(rows: rows),
        ),
      ],
    );
  }
}

class _ChurnRiskSection extends StatelessWidget {
  const _ChurnRiskSection({
    required this.level,
    required this.risks,
    required this.salonName,
  });

  final String level;
  final List<ChurnRiskModel> risks;
  final String salonName;

  String get _title => switch (level) {
    'high' => 'Risque élevé',
    'medium' => 'Risque moyen',
    _ => 'Risque faible',
  };

  Color get _color => switch (level) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: AppTypography.bodySmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final risk in risks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: KynzaCard(
                child: Row(
                  children: [
                    KynzaAvatar(fullName: risk.clientName, size: AvatarSize.sm),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(risk.clientName, style: AppTypography.body),
                          Text(
                            'Absent depuis ${risk.daysSinceLastVisit} jours',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      onPressed: () => ShareService.shareWinBackMessage(
                        salonName,
                        risk.clientName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamAnalyticsTab extends ConsumerWidget {
  const _TeamAnalyticsTab({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isOwner = profile?.role == UserRole.owner;
    final performanceAsync = ref.watch(employeePerformanceProvider(salonId));
    final selectedMonth = ref.watch(selectedPerformanceMonthProvider);

    if (!isOwner) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Réservé au propriétaire',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                "Les performances de l'équipe ne sont visibles que par le propriétaire.",
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_monthLabel(selectedMonth), style: AppTypography.h3),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  ref.read(selectedPerformanceMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month - 1),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  ref.read(selectedPerformanceMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month + 1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        performanceAsync.when(
          loading: () => const KynzaSkeleton(height: 200),
          error: (_, __) => KynzaErrorState(
            message: 'Impossible de charger la performance équipe.',
            onRetry: () => ref.invalidate(employeePerformanceProvider(salonId)),
          ),
          data: (staff) {
            if (staff.isEmpty) {
              return KynzaEmptyState(
                icon: Icons.people_outline,
                title: 'Aucune donnée équipe',
                subtitle:
                    'Les performances apparaîtront après les premiers RDV.',
                ctaLabel: 'Inviter votre équipe',
                onCta: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StaffInviteScreen(salonId: salonId),
                  ),
                ),
              );
            }
            final sorted = [...staff]
              ..sort((a, b) => b.revenueBif.compareTo(a.revenueBif));
            return Column(
              children: [
                KynzaBarChartFl(
                  title: 'CA par staff',
                  bars: [
                    for (final s in sorted)
                      BarData(label: s.displayName, value: s.revenueBif),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                for (var i = 0; i < sorted.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: KynzaCard(
                      child: Row(
                        children: [
                          Text('#${i + 1}', style: AppTypography.h3),
                          const SizedBox(width: AppSpacing.md),
                          KynzaAvatar(
                            fullName: sorted[i].displayName,
                            avatarUrl: sorted[i].avatarUrl,
                            size: AvatarSize.sm,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              sorted[i].displayName,
                              style: AppTypography.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${sorted[i].completions} ✓ · ${sorted[i].noShows} ✗',
                                style: AppTypography.bodySmall,
                              ),
                              if (sorted[i].avgRating != null)
                                Text(
                                  '⭐ ${sorted[i].avgRating!.toStringAsFixed(1)}',
                                  style: AppTypography.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: KynzaButton(
                        label: 'Exporter rapport (PDF)',
                        variant: KynzaButtonVariant.secondary,
                        onPressed: () => _exportPdf(ref, sorted, selectedMonth),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KynzaButton(
                        label: 'Exporter CSV',
                        variant: KynzaButtonVariant.secondary,
                        onPressed: () => ShareService.shareCsv(
                          CsvExporter.staffPerformanceToCsv(sorted),
                          'kynza-equipe-${selectedMonth.year}-${selectedMonth.month}.csv',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _exportPdf(
    WidgetRef ref,
    List<StaffMonthlyPerformanceModel> staff,
    DateTime month,
  ) async {
    final salon = ref.read(ownerSalonProvider).valueOrNull;
    final summaryAsync = ref.read(dashboardSummaryProvider(salonId));
    if (salon == null || summaryAsync.valueOrNull == null) return;
    final topStaff = staff
        .map(
          (s) => TopStaffModel(
            salonId: s.salonId,
            staffId: s.staffId,
            displayName: s.displayName,
            avatarUrl: s.avatarUrl,
            bookingCount: s.completions,
            revenueBif: s.revenueBif,
            weekStart: month,
          ),
        )
        .toList();
    final bytes = await ExportService.generateRevenueReport(
      salon: salon,
      summary: summaryAsync.valueOrNull!,
      range: DateRange.last30days,
      topStaff: topStaff,
    );
    await ExportService.sharePdf(bytes, 'kynza-equipe-${salon.id}.pdf');
  }

  String _monthLabel(DateTime month) {
    const labels = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${labels[month.month - 1]} ${month.year}';
  }
}

class _ForecastTab extends ConsumerWidget {
  const _ForecastTab({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(revenueForecastProvider(salonId));
    final weekdayAsync = ref.watch(bookingsByWeekdayProvider(salonId));
    final hourAsync = ref.watch(bookingsByHourProvider(salonId));
    final summaryAsync = ref.watch(dashboardSummaryProvider(salonId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('Prévision sur 12 semaines', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        forecastAsync.when(
          loading: () => const KynzaSkeleton(height: 220),
          error: (_, __) => KynzaErrorState(
            message: 'Impossible de calculer les prévisions.',
            onRetry: () => ref.invalidate(revenueForecastProvider(salonId)),
          ),
          data: (points) {
            if (points.length < 2) {
              return const Text(
                "Pas encore assez d'historique pour une prévision.",
                style: AppTypography.bodySmall,
              );
            }
            final actuals = points.where((p) => p.actualBif != null).toList();
            final forecasts = points
                .where((p) => p.forecastBif != null)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KynzaLineChart(
                  title: '',
                  series: [
                    KynzaLineChartSeries(
                      spots: [
                        for (var i = 0; i < actuals.length; i++)
                          FlSpot(
                            i.toDouble(),
                            actuals[i].actualBif!.toDouble(),
                          ),
                      ],
                    ),
                    KynzaLineChartSeries(
                      dashed: true,
                      color: AppColors.textSecondary,
                      spots: [
                        for (var i = 0; i < forecasts.length; i++)
                          FlSpot(
                            (actuals.length - 1 + i).toDouble(),
                            forecasts[i].forecastBif!.toDouble(),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InsightChip(label: _trendLabel(actuals)),
                    weekdayAsync.maybeWhen(
                      data: (counts) =>
                          _InsightChip(label: _bestWeekdayLabel(counts)),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.table_chart_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Exporter (CSV)',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      onPressed: () => ShareService.shareCsv(
                        CsvExporter.revenueToCsv(points),
                        'kynza-previsions-$salonId.csv',
                      ),
                    ),
                    hourAsync.maybeWhen(
                      data: (counts) =>
                          _InsightChip(label: _peakHourLabel(counts)),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        summaryAsync.maybeWhen(
          data: (summary) {
            if (summary.occupancyRate >= 70) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                "Occupation à ${summary.occupancyRate.round()}% — pensez à relancer vos clients pour remplir votre planning.",
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _trendLabel(List points) {
    if (points.length < 2) return '→ Stable';
    final first = points.first.actualBif as int;
    final last = points.last.actualBif as int;
    if (first == 0) return last > 0 ? '↑ En croissance' : '→ Stable';
    final change = (last - first) / first;
    if (change > 0.05) return '↑ En croissance';
    if (change < -0.05) return '↓ En baisse';
    return '→ Stable';
  }

  String _bestWeekdayLabel(Map<int, int> counts) {
    if (counts.values.every((v) => v == 0)) return 'Meilleur jour : —';
    final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return 'Meilleur jour : ${_weekdayLabels[best.key - 1]}';
  }

  String _peakHourLabel(Map<int, int> counts) {
    if (counts.values.every((v) => v == 0)) return 'Heure de pointe : —';
    final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return 'Heure de pointe : ${best.key}h';
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(label, style: AppTypography.bodySmall),
    );
  }
}
