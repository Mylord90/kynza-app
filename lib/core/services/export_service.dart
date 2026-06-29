import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../enums/date_range.dart';
import '../models/analytics/dashboard_summary_model.dart';
import '../models/analytics/top_service_model.dart';
import '../models/analytics/top_staff_model.dart';
import '../models/billing/invoice_model.dart';
import '../models/salon_full_model.dart';
import '../utils/currency_formatter.dart';

const _gold = PdfColor.fromInt(0xFFEAB308);
const _grey = PdfColor.fromInt(0xFF71717A);

abstract class ExportService {
  /// KPI summary + top services + top staff (owner only — pass an empty
  /// [topStaff] for any non-owner viewer, R11) + the daily revenue series
  /// already loaded for the dashboard's selected period.
  static Future<Uint8List> generateRevenueReport({
    required SalonFullModel salon,
    required DashboardSummary summary,
    required DateRange range,
    List<TopServiceModel> topServices = const [],
    List<TopStaffModel> topStaff = const [],
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          _header(salon.name, 'Rapport de revenus — ${range.label}'),
          pw.SizedBox(height: 16),
          _sectionTitle('Résumé'),
          pw.TableHelper.fromTextArray(
            headers: ['Indicateur', 'Valeur'],
            data: [
              ['Revenu', CurrencyFormatter.formatBif(summary.revenueBif)],
              ['Réservations', '${summary.bookingsTotal}'],
              ['Taux de remplissage', '${summary.occupancyRate.round()}%'],
              ['Taux de no-show', '${summary.noShowRate.round()}%'],
              ["Taux d'annulation", '${summary.cancellationRate.round()}%'],
            ],
          ),
          if (topServices.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Top services'),
            pw.TableHelper.fromTextArray(
              headers: ['Service', 'RDV', 'Revenu'],
              data: [
                for (final s in topServices)
                  [
                    s.serviceName,
                    '${s.bookingCount}',
                    CurrencyFormatter.formatBif(s.totalRevenueBif),
                  ],
              ],
            ),
          ],
          if (topStaff.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Top équipe'),
            pw.TableHelper.fromTextArray(
              headers: ['Membre', 'RDV', 'Revenu'],
              data: [
                for (final s in topStaff)
                  [
                    s.displayName,
                    '${s.bookingCount}',
                    CurrencyFormatter.formatBif(s.revenueBif),
                  ],
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('Évolution du revenu'),
          pw.TableHelper.fromTextArray(
            headers: ['Jour', 'Revenu', 'RDV'],
            data: [
              for (final kpi in summary.dailySeries)
                [
                  '${kpi.day.day}/${kpi.day.month}',
                  CurrencyFormatter.formatBif(kpi.revenueBif),
                  '${kpi.bookingsTotal}',
                ],
            ],
          ),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required String salonName,
    required String planName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(salonName, 'Facture ${invoice.reference}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Champ', 'Détail'],
              data: [
                ['Référence', invoice.reference],
                ['Plan', planName],
                ['Montant', CurrencyFormatter.formatBif(invoice.amountBif)],
                ['Statut', invoice.status],
                if (invoice.createdAt != null)
                  [
                    'Émise le',
                    '${invoice.createdAt!.day}/${invoice.createdAt!.month}/${invoice.createdAt!.year}',
                  ],
              ],
            ),
            if (invoice.paymentInstructions != null) ...[
              pw.SizedBox(height: 16),
              _sectionTitle('Instructions de paiement'),
              pw.Text(invoice.paymentInstructions!),
            ],
            pw.SizedBox(height: 24),
            _footer(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  static pw.Widget _header(String subjectName, String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'KYNZA',
            style: const pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _gold,
            ),
          ),
          pw.Text(subjectName, style: const pw.TextStyle(fontSize: 14)),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: _grey)),
      pw.Divider(),
    ],
  );

  static pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _footer() => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      'Généré par KYNZA — kynza.app',
      style: const pw.TextStyle(fontSize: 10, color: _grey),
    ),
  );
}
