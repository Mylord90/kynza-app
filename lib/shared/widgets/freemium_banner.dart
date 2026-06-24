import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/freemium_service.dart';
import '../../features/salon/application/providers/salon_providers.dart';
import 'kynza_button.dart';

/// Shown at the top of the Owner's Calendrier tab. Color escalates
/// amber → red as monthly_bookings_count climbs toward the free-plan
/// limit (KynzaConstants.maxFreeBookings).
class FreemiumBanner extends ConsumerWidget {
  const FreemiumBanner({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon == null) return const SizedBox.shrink();

    final level = FreemiumService.evaluate(salon);
    final message = FreemiumService.messageFor(level, salon);
    if (message == null) return const SizedBox.shrink();

    final color = level == FreemiumLevel.red || level == FreemiumLevel.blocked
        ? AppColors.error
        : AppColors.warning;

    return AnimatedContainer(
      duration: AppDurations.medium,
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.md_,
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            child: const Text(
              'Passer à Pro',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocks new booking creation once the free plan's monthly quota is
/// fully consumed (FreemiumLevel.blocked) — shown instead of letting the
/// action silently fail.
Future<void> showFreemiumLimitModal(
  BuildContext context, {
  required VoidCallback onUpgrade,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg_),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.bolt, color: AppColors.primary, size: 40),
            const SizedBox(height: AppSpacing.md),
            const Text('Limite atteinte', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Vos clients attendent. Passez au plan Pro pour des réservations illimitées.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaButton(
              label: 'Passer à Pro →',
              onPressed: () {
                Navigator.of(context).pop();
                onUpgrade();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
