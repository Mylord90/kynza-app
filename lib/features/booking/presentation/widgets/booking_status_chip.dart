import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: booking.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: booking.statusColor),
      ),
      child: Text(
        booking.statusLabel,
        style: AppTypography.bodySmall.copyWith(color: booking.statusColor),
      ),
    );
  }
}
