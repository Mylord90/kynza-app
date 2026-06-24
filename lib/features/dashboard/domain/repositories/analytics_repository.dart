import '../../../../core/enums/date_range.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/salon_kpi_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';

abstract class AnalyticsRepository {
  Future<DashboardSummary> getSummary(String salonId, DateRange range);
  Future<List<SalonKpiModel>> getDailyKpis(String salonId, DateRange range);
  Future<List<TopServiceModel>> getTopServices(String salonId, DateTime month);
  Future<List<TopStaffModel>> getTopStaff(String salonId, DateTime weekStart);
}
