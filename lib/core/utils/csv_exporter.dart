import 'package:csv/csv.dart';
import '../models/analytics/client_ltv_model.dart';
import '../models/analytics/revenue_point_model.dart';
import '../models/analytics/staff_monthly_performance_model.dart';
import '../models/audit_log_model.dart';
import '../models/booking_model.dart';

abstract class CsvExporter {
  static String bookingsToCsv(List<BookingModel> bookings) {
    final rows = [
      ['Date', 'Client', 'Service', 'Praticien', 'Statut', 'Montant (FBu)'],
      for (final b in bookings)
        [
          '${b.startTime.day}/${b.startTime.month}/${b.startTime.year}',
          b.client?.fullName ?? b.clientId,
          b.service?.name ?? b.serviceId,
          b.practitioner?.displayName ?? b.practitionerId,
          b.status.name,
          b.amountBif,
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  static String staffPerformanceToCsv(List<StaffMonthlyPerformanceModel> data) {
    final rows = [
      [
        'Membre',
        'Complétés',
        'No-shows',
        'Annulations',
        'Revenu (FBu)',
        'Note',
      ],
      for (final s in data)
        [
          s.displayName,
          s.completions,
          s.noShows,
          s.cancellations,
          s.revenueBif,
          s.avgRating ?? '',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  static String clientsToCsv(List<ClientLtvModel> clients) {
    final rows = [
      ['Client', 'Visites', 'Total dépensé (FBu)', 'Dernière visite'],
      for (final c in clients)
        [
          c.clientName,
          c.visitCount,
          c.totalSpentBif,
          c.lastVisitAt == null
              ? ''
              : '${c.lastVisitAt!.day}/${c.lastVisitAt!.month}/${c.lastVisitAt!.year}',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  static String auditLogsToCsv(List<AuditLogModel> logs) {
    final rows = [
      ['Date', 'Action', 'Utilisateur', 'Sévérité', 'Sensible'],
      for (final l in logs)
        [
          l.createdAt == null ? '' : l.createdAt!.toIso8601String(),
          l.typeAction,
          l.userName ?? l.userId ?? '',
          l.severity,
          l.isSensitive ? 'oui' : 'non',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  static String revenueToCsv(List<RevenuePointModel> data) {
    final rows = [
      ['Période', 'Réel (FBu)', 'Prévision (FBu)'],
      for (final p in data)
        [
          '${p.periodStart.day}/${p.periodStart.month}/${p.periodStart.year}',
          p.actualBif ?? '',
          p.forecastBif ?? '',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
