import '../../../../core/enums/date_range.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/analytics/churn_risk_model.dart';
import '../../../../core/models/analytics/client_ltv_model.dart';
import '../../../../core/models/analytics/cohort_retention_model.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/revenue_point_model.dart';
import '../../../../core/models/analytics/salon_kpi_model.dart';
import '../../../../core/models/analytics/staff_monthly_performance_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/timezone_service.dart';
import '../../../../core/utils/linear_regression.dart';
import '../../../../core/utils/trend_calculator.dart';
import '../../domain/repositories/analytics_repository.dart';

String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

DateTime _bucketStart(DateTime day, AnalyticsGroupBy groupBy) {
  switch (groupBy) {
    case AnalyticsGroupBy.day:
      return DateTime(day.year, day.month, day.day);
    case AnalyticsGroupBy.week:
      final monday = DateTime(
        day.year,
        day.month,
        day.day,
      ).subtract(Duration(days: day.weekday - 1));
      return monday;
    case AnalyticsGroupBy.month:
      return DateTime(day.year, day.month, 1);
    case AnalyticsGroupBy.year:
      return DateTime(day.year, 1, 1);
  }
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  @override
  Future<List<SalonKpiModel>> getDailyKpis(
    String salonId,
    DateRange range,
  ) async {
    try {
      final today = DateTime.now();
      final start = today.subtract(Duration(days: range.days - 1));
      final rows = await SupabaseService.from('v_salon_kpis')
          .select()
          .eq('salon_id', salonId)
          .gte('day', _isoDate(start))
          .lte('day', _isoDate(today))
          .order('day');
      return rows.map(SalonKpiModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les statistiques.');
    }
  }

  Future<List<SalonKpiModel>> _previousPeriodKpis(
    String salonId,
    DateRange range,
  ) async {
    final today = DateTime.now();
    final currentStart = today.subtract(Duration(days: range.days - 1));
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: range.days - 1));
    final rows = await SupabaseService.from('v_salon_kpis')
        .select()
        .eq('salon_id', salonId)
        .gte('day', _isoDate(previousStart))
        .lte('day', _isoDate(previousEnd));
    return rows.map(SalonKpiModel.fromSupabase).toList();
  }

  @override
  Future<DashboardSummary> getSummary(String salonId, DateRange range) async {
    final daily = await getDailyKpis(salonId, range);
    final previous = await _previousPeriodKpis(salonId, range);

    final revenueBif = daily.fold(0, (sum, k) => sum + k.revenueBif);
    final bookingsTotal = daily.fold(0, (sum, k) => sum + k.bookingsTotal);
    final bookingsCompleted = daily.fold(
      0,
      (sum, k) => sum + k.bookingsCompleted,
    );
    final bookingsCancelled = daily.fold(
      0,
      (sum, k) => sum + k.bookingsCancelled,
    );
    final bookingsNoShow = daily.fold(0, (sum, k) => sum + k.bookingsNoShow);
    final grossBookings = bookingsTotal + bookingsCancelled + bookingsNoShow;

    final previousRevenue = previous.fold(0, (sum, k) => sum + k.revenueBif);
    final previousBookings = previous.fold(
      0,
      (sum, k) => sum + k.bookingsTotal,
    );

    return DashboardSummary(
      revenueBif: revenueBif,
      bookingsTotal: bookingsTotal,
      bookingsCompleted: bookingsCompleted,
      bookingsCancelled: bookingsCancelled,
      bookingsNoShow: bookingsNoShow,
      noShowRate: grossBookings == 0
          ? 0
          : (bookingsNoShow / grossBookings) * 100,
      cancellationRate: grossBookings == 0
          ? 0
          : (bookingsCancelled / grossBookings) * 100,
      occupancyRate: bookingsTotal == 0
          ? 0
          : (bookingsTotal / (16 * range.days)).clamp(0, 1) * 100,
      dailySeries: daily,
      revenueTrendPct: TrendCalculator.percentChange(
        revenueBif,
        previousRevenue,
      ),
      bookingsTrendPct: TrendCalculator.percentChange(
        bookingsTotal,
        previousBookings,
      ),
    );
  }

  @override
  Future<List<TopServiceModel>> getTopServices(
    String salonId,
    DateTime month,
  ) async {
    try {
      final monthStart = DateTime.utc(month.year, month.month, 1);
      final monthEnd = DateTime.utc(
        month.month == 12 ? month.year + 1 : month.year,
        month.month == 12 ? 1 : month.month + 1,
        1,
      );
      final rows = await SupabaseService.from('v_top_services')
          .select()
          .eq('salon_id', salonId)
          .gte('month', monthStart.toIso8601String())
          .lt('month', monthEnd.toIso8601String())
          .order('booking_count', ascending: false);
      return rows.map(TopServiceModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les top services.');
    }
  }

  @override
  Future<List<TopStaffModel>> getTopStaff(
    String salonId,
    DateTime weekStart,
  ) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final rows = await SupabaseService.from('v_top_staff')
          .select()
          .eq('salon_id', salonId)
          .gte('week_start', weekStart.toIso8601String())
          .lt('week_start', weekEnd.toIso8601String())
          .order('booking_count', ascending: false);
      return rows.map(TopStaffModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger le classement équipe.');
    }
  }

  @override
  Future<List<RevenuePointModel>> getRevenueByPeriod(
    String salonId,
    DateRange range,
    AnalyticsGroupBy groupBy,
  ) async {
    final daily = await getDailyKpis(salonId, range);
    final buckets = <DateTime, int>{};
    for (final kpi in daily) {
      final key = _bucketStart(kpi.day, groupBy);
      buckets[key] = (buckets[key] ?? 0) + kpi.revenueBif;
    }
    final sortedKeys = buckets.keys.toList()..sort();
    return sortedKeys
        .map((k) => RevenuePointModel(periodStart: k, actualBif: buckets[k]))
        .toList();
  }

  @override
  Future<List<ClientLtvModel>> getClientLifetimeValues(String salonId) async {
    try {
      final rows = await SupabaseService.from('v_client_ltv')
          .select()
          .eq('salon_id', salonId)
          .order('total_spent_bif', ascending: false);
      return rows.map(ClientLtvModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger la valeur des clients.');
    }
  }

  @override
  Future<List<ClientLtvModel>> getTopClients(String salonId, int limit) async {
    final all = await getClientLifetimeValues(salonId);
    return all.take(limit).toList();
  }

  @override
  Future<List<CohortRetentionModel>> getCohortRetention(String salonId) async {
    try {
      final rows = await SupabaseService.client.rpc(
        'get_cohort_retention',
        params: {'p_salon_id': salonId},
      );
      return (rows as List)
          .map(
            (r) => CohortRetentionModel.fromSupabase(r as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger la rétention des cohortes.',
      );
    }
  }

  @override
  Future<List<ChurnRiskModel>> getChurnRisks(String salonId) async {
    try {
      final rows = await SupabaseService.from('v_churn_risk')
          .select()
          .eq('salon_id', salonId)
          .order('days_since_last_visit', ascending: false);
      return rows.map(ChurnRiskModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les clients à risque.');
    }
  }

  @override
  Future<List<RevenuePointModel>> getRevenueForecast(String salonId) async {
    try {
      final today = DateTime.now();
      final start = today.subtract(const Duration(days: 84));
      final rows = await SupabaseService.from('v_salon_kpis')
          .select()
          .eq('salon_id', salonId)
          .gte('day', _isoDate(start))
          .lte('day', _isoDate(today))
          .order('day');
      final daily = rows.map(SalonKpiModel.fromSupabase).toList();

      final weekly = <DateTime, int>{};
      for (final kpi in daily) {
        final weekStart = _bucketStart(kpi.day, AnalyticsGroupBy.week);
        weekly[weekStart] = (weekly[weekStart] ?? 0) + kpi.revenueBif;
      }
      final sortedWeeks = weekly.keys.toList()..sort();
      if (sortedWeeks.isEmpty) return [];

      final actuals = sortedWeeks
          .map((w) => RevenuePointModel(periodStart: w, actualBif: weekly[w]))
          .toList();
      if (actuals.length < 2) return actuals;

      final origin = actuals.first.periodStart;
      final regression = LinearRegression.fit(
        actuals
            .map((p) => p.periodStart.difference(origin).inDays / 7)
            .toList(),
        actuals.map((p) => p.actualBif!.toDouble()).toList(),
      );

      final lastWeek = sortedWeeks.last;
      final forecastPoints = List.generate(12, (i) {
        final weekStart = lastWeek.add(Duration(days: 7 * (i + 1)));
        final x = weekStart.difference(origin).inDays / 7;
        final predicted = (regression.slope * x + regression.intercept)
            .round()
            .clamp(0, 1 << 31);
        return RevenuePointModel(
          periodStart: weekStart,
          forecastBif: predicted,
        );
      });

      return [...actuals, ...forecastPoints];
    } catch (_) {
      throw const AppException('Impossible de calculer les prévisions.');
    }
  }

  @override
  Future<List<StaffMonthlyPerformanceModel>> getEmployeePerformance(
    String salonId,
    DateTime month,
  ) async {
    try {
      final monthStart = DateTime.utc(month.year, month.month, 1);
      final monthEnd = DateTime.utc(
        month.month == 12 ? month.year + 1 : month.year,
        month.month == 12 ? 1 : month.month + 1,
        1,
      );
      final rows = await SupabaseService.from('v_staff_monthly_performance')
          .select()
          .eq('salon_id', salonId)
          .gte('month', monthStart.toIso8601String())
          .lt('month', monthEnd.toIso8601String())
          .order('revenue_bif', ascending: false);
      return rows.map(StaffMonthlyPerformanceModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger la performance de l\'équipe.',
      );
    }
  }

  @override
  Future<Map<int, int>> getBookingsByHour(
    String salonId,
    DateRange range,
  ) async {
    try {
      final today = DateTime.now();
      final start = today.subtract(Duration(days: range.days - 1));
      final rows = await SupabaseService.from('bookings')
          .select('start_time')
          .eq('salon_id', salonId)
          .gte('start_time', start.toIso8601String())
          .isFilter('deleted_at', null)
          .not('status', 'in', '(cancelled,no_show)');

      final buckets = <int, int>{for (var h = 0; h < 24; h++) h: 0};
      for (final row in rows) {
        final startTime = DateTime.parse(row['start_time'] as String);
        final hour = TimeZoneService.toLocal(startTime).hour;
        buckets[hour] = (buckets[hour] ?? 0) + 1;
      }
      return buckets;
    } catch (_) {
      throw const AppException('Impossible de charger la répartition horaire.');
    }
  }

  @override
  Future<Map<String, int>> getNewVsReturning(
    String salonId,
    DateRange range,
  ) async {
    try {
      final today = DateTime.now();
      final start = today.subtract(Duration(days: range.days - 1));
      final rows = await SupabaseService.from('bookings')
          .select('client_id, start_time')
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .not('status', 'in', '(cancelled,no_show)');

      final firstVisit = <String, DateTime>{};
      for (final row in rows) {
        final clientId = row['client_id'] as String;
        final startTime = DateTime.parse(row['start_time'] as String);
        final existing = firstVisit[clientId];
        if (existing == null || startTime.isBefore(existing)) {
          firstVisit[clientId] = startTime;
        }
      }

      final periodClientIds = <String>{};
      for (final row in rows) {
        final startTime = DateTime.parse(row['start_time'] as String);
        if (!startTime.isBefore(start) && !startTime.isAfter(today)) {
          periodClientIds.add(row['client_id'] as String);
        }
      }

      var newCount = 0;
      var returningCount = 0;
      for (final clientId in periodClientIds) {
        if (firstVisit[clientId]!.isBefore(start)) {
          returningCount++;
        } else {
          newCount++;
        }
      }
      return {'new': newCount, 'returning': returningCount};
    } catch (_) {
      throw const AppException('Impossible de calculer les nouveaux clients.');
    }
  }

  @override
  Future<Map<int, int>> getBookingsByWeekday(String salonId) async {
    try {
      final today = DateTime.now();
      final start = today.subtract(const Duration(days: 84));
      final rows = await SupabaseService.from('v_salon_kpis')
          .select('day, bookings_total')
          .eq('salon_id', salonId)
          .gte('day', _isoDate(start))
          .lte('day', _isoDate(today));

      final buckets = <int, int>{for (var d = 1; d <= 7; d++) d: 0};
      for (final row in rows) {
        final day = DateTime.parse(row['day'] as String);
        final count = row['bookings_total'] as int;
        buckets[day.weekday] = (buckets[day.weekday] ?? 0) + count;
      }
      return buckets;
    } catch (_) {
      throw const AppException(
        'Impossible de charger la répartition par jour.',
      );
    }
  }
}
