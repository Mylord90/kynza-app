import '../../../../core/enums/date_range.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/salon_kpi_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/trend_calculator.dart';
import '../../domain/repositories/analytics_repository.dart';

String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

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
}
