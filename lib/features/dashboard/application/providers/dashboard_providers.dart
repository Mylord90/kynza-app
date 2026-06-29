import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/date_range.dart';
import '../../../../core/models/analytics/churn_risk_model.dart';
import '../../../../core/models/analytics/client_ltv_model.dart';
import '../../../../core/models/analytics/cohort_retention_model.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/revenue_point_model.dart';
import '../../../../core/models/analytics/staff_monthly_performance_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepositoryImpl(),
);

final selectedPeriodProvider = StateProvider<DateRange>(
  (ref) => DateRange.today,
);

/// Re-fetches every 5 minutes while watched (kynza-supabase-backend.md —
/// live data TTL) in addition to refetching whenever the period changes.
final dashboardSummaryProvider = FutureProvider.autoDispose
    .family<DashboardSummary, String>((ref, salonId) {
      final timer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      final range = ref.watch(selectedPeriodProvider);
      return ref.read(analyticsRepositoryProvider).getSummary(salonId, range);
    });

final topServicesProvider = FutureProvider.autoDispose
    .family<List<TopServiceModel>, String>((ref, salonId) {
      final now = DateTime.now();
      return ref
          .read(analyticsRepositoryProvider)
          .getTopServices(salonId, DateTime(now.year, now.month));
    });

final topStaffProvider = FutureProvider.autoDispose
    .family<List<TopStaffModel>, String>((ref, salonId) {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );
      return ref
          .read(analyticsRepositoryProvider)
          .getTopStaff(salonId, weekStart);
    });

// ── Phase 4 — Clients sub-tab ──────────────────────────────────────────
final clientLtvProvider = FutureProvider.autoDispose
    .family<List<ClientLtvModel>, String>(
      (ref, salonId) => ref
          .read(analyticsRepositoryProvider)
          .getClientLifetimeValues(salonId),
    );

final topClientsProvider = FutureProvider.autoDispose
    .family<List<ClientLtvModel>, String>(
      (ref, salonId) =>
          ref.read(analyticsRepositoryProvider).getTopClients(salonId, 5),
    );

final churnRisksProvider = FutureProvider.autoDispose
    .family<List<ChurnRiskModel>, String>(
      (ref, salonId) =>
          ref.read(analyticsRepositoryProvider).getChurnRisks(salonId),
    );

final cohortRetentionProvider = FutureProvider.autoDispose
    .family<List<CohortRetentionModel>, String>(
      (ref, salonId) =>
          ref.read(analyticsRepositoryProvider).getCohortRetention(salonId),
    );

final newVsReturningProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, salonId) {
      final range = ref.watch(selectedPeriodProvider);
      return ref
          .read(analyticsRepositoryProvider)
          .getNewVsReturning(salonId, range);
    });

// ── Phase 4 — Équipe sub-tab ────────────────────────────────────────────
final selectedPerformanceMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final employeePerformanceProvider = FutureProvider.autoDispose
    .family<List<StaffMonthlyPerformanceModel>, String>((ref, salonId) {
      final month = ref.watch(selectedPerformanceMonthProvider);
      return ref
          .read(analyticsRepositoryProvider)
          .getEmployeePerformance(salonId, month);
    });

// ── Phase 4 — Prévisions sub-tab ────────────────────────────────────────
final revenueForecastProvider = FutureProvider.autoDispose
    .family<List<RevenuePointModel>, String>(
      (ref, salonId) =>
          ref.read(analyticsRepositoryProvider).getRevenueForecast(salonId),
    );

final bookingsByHourProvider = FutureProvider.autoDispose
    .family<Map<int, int>, String>((ref, salonId) {
      final range = ref.watch(selectedPeriodProvider);
      return ref
          .read(analyticsRepositoryProvider)
          .getBookingsByHour(salonId, range);
    });

final bookingsByWeekdayProvider = FutureProvider.autoDispose
    .family<Map<int, int>, String>(
      (ref, salonId) =>
          ref.read(analyticsRepositoryProvider).getBookingsByWeekday(salonId),
    );
