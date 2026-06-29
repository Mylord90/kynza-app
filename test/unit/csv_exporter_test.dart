import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/analytics/client_ltv_model.dart';
import 'package:kynza/core/models/analytics/revenue_point_model.dart';
import 'package:kynza/core/models/analytics/staff_monthly_performance_model.dart';
import 'package:kynza/core/utils/csv_exporter.dart';

void main() {
  group('CsvExporter.staffPerformanceToCsv', () {
    test('includes the header row and one row per staff member', () {
      final csv = CsvExporter.staffPerformanceToCsv([
        StaffMonthlyPerformanceModel(
          salonId: 's1',
          staffId: 'st1',
          displayName: 'Eric',
          month: DateTime(2026, 6, 1),
          completions: 10,
          noShows: 1,
          cancellations: 0,
          revenueBif: 50000,
          avgRating: 4.5,
        ),
      ]);
      expect(csv, contains('Membre'));
      expect(csv, contains('Eric'));
      expect(csv, contains('50000'));
    });
  });

  group('CsvExporter.clientsToCsv', () {
    test('includes the header row and one row per client', () {
      final csv = CsvExporter.clientsToCsv([
        const ClientLtvModel(
          salonId: 's1',
          clientId: 'c1',
          clientName: 'Jeanne',
          visitCount: 3,
          totalSpentBif: 30000,
        ),
      ]);
      expect(csv, contains('Client'));
      expect(csv, contains('Jeanne'));
      expect(csv, contains('30000'));
    });
  });

  group('CsvExporter.revenueToCsv', () {
    test('includes both actual and forecast columns', () {
      final csv = CsvExporter.revenueToCsv([
        RevenuePointModel(periodStart: DateTime(2026, 6, 1), actualBif: 10000),
        RevenuePointModel(
          periodStart: DateTime(2026, 6, 8),
          forecastBif: 12000,
        ),
      ]);
      expect(csv, contains('Réel (FBu)'));
      expect(csv, contains('Prévision (FBu)'));
      expect(csv, contains('10000'));
      expect(csv, contains('12000'));
    });
  });
}
