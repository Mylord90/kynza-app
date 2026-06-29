import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/billing_providers.dart';

const _planNames = {'free': 'Gratuit', 'pro': 'Pro', 'premium': 'Premium'};

class InvoiceHistoryScreen extends ConsumerWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Historique des factures')),
      body: salon == null
          ? const Center(child: KynzaSpinner())
          : _InvoiceList(salonId: salon.id),
    );
  }
}

class _InvoiceList extends ConsumerWidget {
  const _InvoiceList({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(salonInvoicesProvider(salonId));

    return invoicesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 72),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: 'Impossible de charger les factures.',
        onRetry: () => ref.invalidate(salonInvoicesProvider(salonId)),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const KynzaEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aucune facture',
            subtitle:
                'Vos factures apparaîtront ici après une demande de mise à niveau.',
            ctaLabel: 'Retour',
            onCta: _noop,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: KynzaCard(
                onTap: () => showKynzaBottomSheet(
                  context,
                  builder: (_) => _InvoiceDetailSheet(invoice: invoice),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invoice.reference, style: AppTypography.mono),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _planNames[invoice.planKey] ?? invoice.planKey,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        KynzaAmountWidget(
                          amountBif: invoice.amountBif,
                          style: AppTypography.amountSm,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _StatusChip(status: invoice.status),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void _noop() {}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      'paid' => ('PAYÉE', KynzaBadgeVariant.success),
      'overdue' => ('EN RETARD', KynzaBadgeVariant.error),
      'void' => ('ANNULÉE', KynzaBadgeVariant.neutral),
      _ => ('EN ATTENTE', KynzaBadgeVariant.warning),
    };
    return KynzaBadge(label: label, variant: variant);
  }
}

class _InvoiceDetailSheet extends ConsumerStatefulWidget {
  const _InvoiceDetailSheet({required this.invoice});

  final InvoiceModel invoice;

  @override
  ConsumerState<_InvoiceDetailSheet> createState() =>
      _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends ConsumerState<_InvoiceDetailSheet> {
  bool _isMarking = false;

  Future<void> _exportPdf(InvoiceModel invoice) async {
    final salon = ref.read(ownerSalonProvider).valueOrNull;
    if (salon == null) return;
    final bytes = await ExportService.generateInvoicePdf(
      invoice: invoice,
      salonName: salon.name,
      planName: _planNames[invoice.planKey] ?? invoice.planKey,
    );
    await ExportService.sharePdf(bytes, '${invoice.reference}.pdf');
  }

  Future<void> _markPaid() async {
    final salon = ref.read(ownerSalonProvider).valueOrNull;
    if (salon == null) return;
    setState(() => _isMarking = true);
    try {
      await ref
          .read(billingNotifierProvider.notifier)
          .markPaid(salon.id, widget.invoice.id!);
      ref.invalidate(ownerSalonProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : 'Une erreur est survenue.',
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(invoice.reference, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _planNames[invoice.planKey] ?? invoice.planKey,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          KynzaAmountWidget(
            amountBif: invoice.amountBif,
            style: AppTypography.amount,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusChip(status: invoice.status),
          if (invoice.isPending && invoice.paymentInstructions != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('Instructions de paiement', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Text(
                invoice.paymentInstructions!,
                style: AppTypography.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          KynzaButton(
            label: 'Exporter facture PDF',
            variant: KynzaButtonVariant.secondary,
            onPressed: () => _exportPdf(invoice),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaButton(
            label: 'Partager la facture',
            variant: KynzaButtonVariant.secondary,
            onPressed: () => ShareService.shareInvoice(
              reference: invoice.reference,
              planName: _planNames[invoice.planKey] ?? invoice.planKey,
              formattedAmount: CurrencyFormatter.formatBif(invoice.amountBif),
              instructions: invoice.paymentInstructions ?? '',
            ),
          ),
          if (invoice.isPending) ...[
            const SizedBox(height: AppSpacing.md),
            KynzaButton(
              label: 'Marquer comme payé',
              isLoading: _isMarking,
              onPressed: _markPaid,
            ),
          ],
        ],
      ),
    );
  }
}
