import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/journey/owner_journey_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/journey_providers.dart';

/// Shown above the KPI grid on the owner Dashboard tab while the journey
/// is incomplete; once it reaches 100% it shows a one-time dismissible
/// success state instead of just disappearing (R04 — never end on a
/// silent state change with no acknowledgement).
class JourneyProgressCard extends ConsumerWidget {
  const JourneyProgressCard({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(ownerJourneyProvider(salonId));
    final dismissed = ref.watch(journeyDismissedProvider(salonId));
    if (dismissed) return const SizedBox.shrink();

    return journeyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xl),
        child: KynzaSkeleton(height: 280),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (journey) {
        if (journey == null) return const SizedBox.shrink();
        return AnimatedSize(
          duration: AppDurations.rich,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: _JourneyCardBody(salonId: salonId, journey: journey),
          ),
        );
      },
    );
  }
}

class _JourneyCardBody extends ConsumerWidget {
  const _JourneyCardBody({required this.salonId, required this.journey});

  final String salonId;
  final OwnerJourneyModel journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xl_,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppRadius.xl),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '🚀 Lancez votre salon',
                          style: AppTypography.h3,
                        ),
                      ),
                      Text(
                        '${journey.completionPct}%',
                        style: AppTypography.amountMd,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProgressBar(pct: journey.completionPct),
                  const SizedBox(height: AppSpacing.lg),
                  for (final step in OwnerJourneyModelX.steps) ...[
                    if (step.index > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _StepRow(step: step, done: journey.isStepDone(step.key)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (journey.isComplete)
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '🎉 Votre salon est prêt !',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(journeyDismissedProvider(salonId).notifier)
                              .dismiss(salonId),
                          child: const Text('Fermer'),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          final next = OwnerJourneyModelX.steps.firstWhere(
                            (s) => !journey.isStepDone(s.key),
                            orElse: () => OwnerJourneyModelX.steps.first,
                          );
                          context.go(next.route);
                        },
                        child: const Text('Continuer la configuration →'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill_,
      child: Container(
        height: 6,
        color: AppColors.surfaceVariant,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: AppDurations.rich,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.goldGradient),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.done});

  final JourneyStep step;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AnimatedScale(
            scale: done ? 1 : 0.85,
            duration: AppDurations.spring,
            curve: Curves.elasticOut,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.success : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                done ? Icons.check : step.icon,
                size: 16,
                color: done ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.h3.copyWith(
                    color: done ? AppColors.textMuted : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(step.subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (!done)
            GestureDetector(
              onTap: () => context.go(step.route),
              child: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
