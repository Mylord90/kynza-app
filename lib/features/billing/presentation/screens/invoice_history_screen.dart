import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/billing_providers.dart';

Map<String, String> _planNames(BuildContext context) => {
  'free': context.l10n.billingPlanNameFree,
  'pro': context.l10n.billingPlanNamePro,
  'premium': context.l10n.billingPlanNamePremium,
};

class InvoiceHistoryScreen extends ConsumerWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.billingInvoicesTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: salon == null
                ? const KynzaLoaderInline(size: KynzaLoaderSize.large)
                : _InvoiceList(salonId: salon.id),
          ),
        ],
      ),
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
          child: KynzaBookingCardSkeleton(),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: context.l10n.billingInvoicesLoadError,
        onRetry: () => ref.invalidate(salonInvoicesProvider(salonId)),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.l10n.billingInvoicesEmptyTitle,
            subtitle: context.l10n.billingInvoicesEmptySubtitle,
            ctaLabel: context.l10n.commonBack,
            onCta: _noop,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async => ref.invalidate(salonInvoicesProvider(salonId)),
          child: ListView.builder(
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
                              _planNames(context)[invoice.planKey] ??
                                  invoice.planKey,
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
          ),
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
      'paid' => (
        context.l10n.billingInvoiceStatusPaid,
        KynzaBadgeVariant.success,
      ),
      'overdue' => (
        context.l10n.billingInvoiceStatusOverdue,
        KynzaBadgeVariant.error,
      ),
      'void' => (
        context.l10n.billingInvoiceStatusVoid,
        KynzaBadgeVariant.neutral,
      ),
      _ => (
        context.l10n.billingInvoiceStatusPending,
        KynzaBadgeVariant.warning,
      ),
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
    final planName = _planNames(context)[invoice.planKey] ?? invoice.planKey;
    final bytes = await ExportService.generateInvoicePdf(
      invoice: invoice,
      salonName: salon.name,
      planName: planName,
    );
    await ExportService.sharePdf(bytes, '${invoice.reference}.pdf');
  }

  Future<void> _markPaid() async {
    final l10n = context.l10n;
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
          message: e is AppException ? e.message : l10n.errorGeneric,
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
            _planNames(context)[invoice.planKey] ?? invoice.planKey,
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
            Text(
              context.l10n.billingInvoicePaymentInstructionsTitle,
              style: AppTypography.h3,
            ),
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
            label: context.l10n.billingInvoiceExportPdfButton,
            variant: KynzaButtonVariant.secondary,
            onPressed: () => _exportPdf(invoice),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaButton(
            label: context.l10n.billingInvoiceShareButton,
            variant: KynzaButtonVariant.secondary,
            onPressed: () => ShareService.shareInvoice(
              reference: invoice.reference,
              planName: _planNames(context)[invoice.planKey] ?? invoice.planKey,
              formattedAmount: CurrencyFormatter.formatBif(invoice.amountBif),
              instructions: invoice.paymentInstructions ?? '',
            ),
          ),
          if (invoice.isPending) ...[
            const SizedBox(height: AppSpacing.md),
            KynzaButton(
              label: context.l10n.billingInvoiceMarkPaidButton,
              isLoading: _isMarking,
              onPressed: _markPaid,
            ),
          ],
        ],
      ),
    );
  }
}
