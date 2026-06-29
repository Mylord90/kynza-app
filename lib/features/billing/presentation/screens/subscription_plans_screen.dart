import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/kynza_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/models/billing/subscription_plan_model.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/freemium_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/billing_providers.dart';

const _planOrder = {'free': 0, 'pro': 1, 'premium': 2};

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Abonnement KYNZA')),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: salon == null
                ? const Center(child: KynzaSpinner())
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Center(
                        child: KynzaBadge(
                          label: salon.plan == 'free'
                              ? 'PLAN GRATUIT'
                              : 'PLAN ${salon.plan.toUpperCase()}',
                          variant: salon.plan == 'free'
                              ? KynzaBadgeVariant.neutral
                              : KynzaBadgeVariant.gold,
                        ),
                      ),
                      if (salon.plan == 'free') ...[
                        const SizedBox(height: AppSpacing.lg),
                        _UsageCard(salon: salon),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      plansAsync.when(
                        loading: () =>
                            const KynzaSkeleton(height: 220, count: 3),
                        error: (_, __) => KynzaErrorState(
                          message: "Impossible de charger les plans.",
                          onRetry: () =>
                              ref.invalidate(subscriptionPlansProvider),
                        ),
                        data: (plans) {
                          final sorted = [...plans]
                            ..sort(
                              (a, b) => (_planOrder[a.key] ?? 0).compareTo(
                                _planOrder[b.key] ?? 0,
                              ),
                            );
                          return Column(
                            children: [
                              for (final plan in sorted)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: _PlanCard(
                                    plan: plan,
                                    currentPlanKey: salon.plan,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.salon});

  final SalonFullModel salon;

  @override
  Widget build(BuildContext context) {
    final used = salon.monthlyBookingsCount;
    const max = KynzaConstants.maxFreeBookings;
    final pct = (used / max).clamp(0.0, 1.0);
    final level = FreemiumService.evaluate(salon);
    final color = switch (level) {
      FreemiumLevel.red || FreemiumLevel.blocked => AppColors.error,
      FreemiumLevel.amber => AppColors.warning,
      FreemiumLevel.ok => AppColors.primary,
    };

    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$used / $max RDV ce mois', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, _) => Container(
                height: 8,
                color: AppColors.surfaceVariant,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.currentPlanKey});

  final SubscriptionPlanModel plan;
  final String currentPlanKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = plan.key == currentPlanKey;
    final isUpgrade =
        (_planOrder[plan.key] ?? 0) > (_planOrder[currentPlanKey] ?? 0);

    return KynzaCard(
      isFeatured: plan.isFeatured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isFeatured)
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: KynzaBadge(
                  label: 'RECOMMANDÉ',
                  variant: KynzaBadgeVariant.gold,
                ),
              ),
            ),
          Text(plan.name, style: AppTypography.h1),
          Text(plan.tagline, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.priceBif == 0
                    ? '0 FBu'
                    : CurrencyFormatter.formatBif(plan.priceBif),
                style: AppTypography.amount.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(plan.periodLabel, style: AppTypography.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(feature, style: AppTypography.body)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          KynzaButton(
            label: isCurrent
                ? 'Plan actuel'
                : isUpgrade
                ? 'Passer à ${plan.name} →'
                : 'Rétrograder',
            variant: isCurrent
                ? KynzaButtonVariant.secondary
                : isUpgrade
                ? KynzaButtonVariant.primary
                : KynzaButtonVariant.destructive,
            onPressed: isCurrent
                ? null
                : () => isUpgrade
                      ? _showUpgradeSheet(context, ref, plan)
                      : _showDowngradeConfirm(context, ref, plan),
          ),
        ],
      ),
    );
  }

  Future<void> _showDowngradeConfirm(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlanModel plan,
  ) async {
    final salon = ref.read(ownerSalonProvider).valueOrNull;
    if (salon == null) return;
    final confirmed = await showKynzaConfirmDialog(
      context,
      title: 'Rétrograder vers ${plan.name} ?',
      message: 'Votre salon passera immédiatement au plan ${plan.name}.',
    );
    if (!confirmed) return;
    try {
      await ref
          .read(billingNotifierProvider.notifier)
          .downgrade(salon.id, plan.key);
      ref.invalidate(ownerSalonProvider);
      if (context.mounted) {
        showKynzaToast(
          context,
          message: 'Plan mis à jour.',
          level: ToastLevel.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : 'Une erreur est survenue.',
          level: ToastLevel.error,
        );
      }
    }
  }

  Future<void> _showUpgradeSheet(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlanModel plan,
  ) async {
    await showKynzaBottomSheet(
      context,
      builder: (_) => _UpgradeRequestSheet(plan: plan),
    );
  }
}

class _UpgradeRequestSheet extends ConsumerStatefulWidget {
  const _UpgradeRequestSheet({required this.plan});

  final SubscriptionPlanModel plan;

  @override
  ConsumerState<_UpgradeRequestSheet> createState() =>
      _UpgradeRequestSheetState();
}

class _UpgradeRequestSheetState extends ConsumerState<_UpgradeRequestSheet> {
  InvoiceModel? _invoice;
  bool _isLoading = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoice = await ref
          .read(billingNotifierProvider.notifier)
          .requestUpgrade(widget.plan.key);
      if (mounted) setState(() => _invoice = invoice);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AppException ? e.message : 'Une erreur est survenue.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
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
        children: invoice == null
            ? [
                Text(
                  'Vous demandez une mise à niveau vers ${widget.plan.name}.',
                  style: AppTypography.h2,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Notre équipe vous contactera pour le paiement.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: const Text(
                    KynzaConstants.bankTransferInstructions,
                    style: AppTypography.bodySmall,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                KynzaButton(
                  label: 'Confirmer la demande',
                  isLoading: _isLoading,
                  onPressed: _confirm,
                ),
              ]
            : [
                const Text('Demande envoyée ! 🎉', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Référence à inclure : ${invoice.reference}',
                  style: AppTypography.amountMd,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: Text(
                    invoice.paymentInstructions ??
                        KynzaConstants.bankTransferInstructions,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: KynzaButton(
                        label: 'Copier la référence',
                        variant: KynzaButtonVariant.secondary,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: invoice.reference),
                          );
                          if (context.mounted) {
                            showKynzaToast(
                              context,
                              message: 'Référence copiée !',
                              level: ToastLevel.success,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                KynzaButton(
                  label: 'Partager les instructions',
                  variant: KynzaButtonVariant.secondary,
                  onPressed: () => ShareService.shareUpgradeInstructions(
                    planName: widget.plan.name,
                    reference: invoice.reference,
                    instructions:
                        invoice.paymentInstructions ??
                        KynzaConstants.bankTransferInstructions,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                KynzaButton(
                  label: 'Terminer',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(RouteNames.ownerBillingSuccess);
                  },
                ),
              ],
      ),
    );
  }
}
