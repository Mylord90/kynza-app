import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Next-appointment hero card, ~40% of screen height.
/// [onConfirmArrival] is R10 — NEVER wrap this in a confirmation dialog.
class StaffFeaturedCard extends StatelessWidget {
  const StaffFeaturedCard({
    super.key,
    required this.booking,
    required this.onConfirmArrival,
  });

  final BookingModel booking;
  final VoidCallback onConfirmArrival;

  @override
  Widget build(BuildContext context) {
    final clientName = booking.client?.fullName ?? 'Client';
    final serviceName = booking.service?.name ?? '';
    final canConfirm =
        booking.status.name == 'confirmed' &&
        DateTime.now().isAfter(
          booking.startTime.subtract(const Duration(minutes: 30)),
        );

    return FractionallySizedBox(
      heightFactor: 0.4,
      widthFactor: 1,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card_,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prochain rendez-vous',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName, style: AppTypography.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$serviceName · ${DateFormat('HH:mm').format(booking.startTime)}',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (canConfirm)
              KynzaButton(
                label: 'Confirmer arrivée',
                onPressed: onConfirmArrival,
              ),
          ],
        ),
      ),
    );
  }
}
