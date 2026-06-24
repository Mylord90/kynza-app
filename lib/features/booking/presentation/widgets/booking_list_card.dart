import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import 'booking_status_chip.dart';

class BookingListCard extends StatelessWidget {
  const BookingListCard({super.key, required this.booking, this.onTap});

  final BookingModel booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'EEEE d MMMM · HH:mm',
                    'fr_FR',
                  ).format(booking.startTime),
                  style: AppTypography.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                KynzaAmountWidget(
                  amountBif: booking.amountBif,
                  style: AppTypography.amountSm,
                ),
              ],
            ),
          ),
          BookingStatusChip(booking: booking),
        ],
      ),
    );
  }
}
