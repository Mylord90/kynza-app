import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';

/// Calendar day-list tile — left border color encodes priority/status
/// (paid=gold, confirmed=primary, pending=info, cancelled/no-show=muted).
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, required this.onTap});

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md_,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.md_,
          border: Border(
            left: BorderSide(color: booking.statusColor, width: 3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                DateFormat('HH:mm').format(booking.startTime),
                style: AppTypography.mono,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(booking.statusLabel, style: AppTypography.h3)),
            if (booking.isPaid)
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
