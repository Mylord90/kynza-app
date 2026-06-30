import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/loyalty/loyalty_card_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/loyalty_providers.dart';

class LoyaltyCardWidget extends ConsumerWidget {
  const LoyaltyCardWidget({super.key, required this.card});

  final LoyaltyCardModel card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonByIdProvider(card.salonId));
    final programAsync = ref.watch(loyaltyProgramProvider(card.salonId));

    return salonAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: KynzaSkeleton(height: 220),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (salon) {
        if (salon == null) return const SizedBox.shrink();
        final required = programAsync.valueOrNull?.stampsRequired ?? 10;
        final complete = card.isComplete(required);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GestureDetector(
            onTap: () => showKynzaBottomSheet(
              context,
              builder: (_) => _LoyaltyCardDetail(
                card: card,
                salonName: salon.name,
                required: required,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: complete ? AppColors.primary : AppColors.border,
                  width: complete ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      KynzaAvatar(
                        fullName: salon.name,
                        avatarUrl: salon.logoUrl,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(salon.name, style: AppTypography.h3),
                            Text(
                              context.l10n.loyaltyStampsRequired(required),
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _StampGrid(filled: card.stampsCount, total: required),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.loyaltyStampsProgress(card.stampsCount, required),
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: card.progressPct(required)),
                      duration: AppDurations.rich,
                      builder: (context, value, _) => Container(
                        height: 6,
                        color: AppColors.surfaceVariant,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.goldGradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (complete) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.l10n.loyaltyRewardAvailable,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StampGrid extends StatelessWidget {
  const _StampGrid({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedScale(
            scale: i < filled ? 1 : 0.85,
            duration: AppDurations.spring,
            curve: Curves.elasticOut,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? AppColors.primary : null,
                border: i < filled
                    ? null
                    : Border.all(
                        color: AppColors.surfaceVariant,
                        style: BorderStyle.solid,
                      ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.star,
                size: 14,
                color: i < filled
                    ? AppColors.background
                    : AppColors.surfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoyaltyCardDetail extends ConsumerWidget {
  const _LoyaltyCardDetail({
    required this.card,
    required this.salonName,
    required this.required,
  });

  final LoyaltyCardModel card;
  final String salonName;
  final int required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(stampLogsProvider(card.id!));

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
          Text(salonName, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.loyaltyStampLogsTitle,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: logsAsync.when(
              loading: () => const KynzaSkeleton(height: 48, count: 3),
              error: (_, __) => Text(
                context.l10n.loyaltyStampLogsLoadError,
                style: AppTypography.bodySmall,
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text(
                    context.l10n.loyaltyStampLogsEmpty,
                    style: AppTypography.bodySmall,
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            log.stampsDelta >= 0
                                ? Icons.add_circle_outline
                                : Icons.redeem_outlined,
                            size: 18,
                            color: log.stampsDelta >= 0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              log.stampsDelta >= 0
                                  ? context.l10n.loyaltyStampAdded
                                  : context.l10n.loyaltyStampRewardValidated,
                              style: AppTypography.body,
                            ),
                          ),
                          if (log.createdAt != null)
                            Text(
                              '${log.createdAt!.day}/${log.createdAt!.month}/${log.createdAt!.year}',
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          KynzaButton(
            label: context.l10n.loyaltyShowQrButton,
            icon: const Icon(
              Icons.qr_code,
              size: 18,
              color: AppColors.background,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push(RouteNames.clientLoyaltyQrPath(card.id!));
            },
          ),
        ],
      ),
    );
  }
}
