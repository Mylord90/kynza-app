import '../../../../core/enums/date_range.dart';
import '../../../../core/models/analytics/churn_risk_model.dart';
import '../../../../core/models/analytics/client_ltv_model.dart';
import '../../../../core/models/analytics/cohort_retention_model.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/revenue_point_model.dart';
import '../../../../core/models/analytics/salon_kpi_model.dart';
import '../../../../core/models/analytics/staff_monthly_performance_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';

enum AnalyticsGroupBy { day, week, month, year }

abstract class AnalyticsRepository {
  Future<DashboardSummary> getSummary(String salonId, DateRange range);
  Future<List<SalonKpiModel>> getDailyKpis(String salonId, DateRange range);
  Future<List<TopServiceModel>> getTopServices(String salonId, DateTime month);
  Future<List<TopStaffModel>> getTopStaff(String salonId, DateTime weekStart);

  Future<List<RevenuePointModel>> getRevenueByPeriod(
    String salonId,
    DateRange range,
    AnalyticsGroupBy groupBy,
  );
  Future<List<ClientLtvModel>> getClientLifetimeValues(String salonId);
  Future<List<ClientLtvModel>> getTopClients(String salonId, int limit);
  Future<List<CohortRetentionModel>> getCohortRetention(String salonId);
  Future<List<ChurnRiskModel>> getChurnRisks(String salonId);
  Future<List<RevenuePointModel>> getRevenueForecast(String salonId);
  Future<List<StaffMonthlyPerformanceModel>> getEmployeePerformance(
    String salonId,
    DateTime month,
  );
  Future<Map<int, int>> getBookingsByHour(String salonId, DateRange range);
  Future<Map<String, int>> getNewVsReturning(String salonId, DateRange range);

  /// Trailing-84-day booking count per ISO weekday (1=Mon..7=Sun), summed
  /// from `v_salon_kpis.bookings_total` — same trailing window as
  /// [getRevenueForecast] so the "meilleur jour" chip reflects the same
  /// lookback as the forecast it sits next to.
  Future<Map<int, int>> getBookingsByWeekday(String salonId);
}
