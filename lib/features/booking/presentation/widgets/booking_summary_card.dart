import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/booking_flow_provider.dart';

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.state,
    this.compact = false,
  });

  final BookingFlowState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final slot = state.selectedSlot;
    final dateFmt = slot != null
        ? DateFormat('EEEE d MMMM', 'fr_FR').format(slot.startTime)
        : '';
    final timeFmt = slot != null
        ? '${slot.startTime.hour.toString().padLeft(2, '0')}:'
              '${slot.startTime.minute.toString().padLeft(2, '0')}'
        : '';

    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KynzaAvatar(
                fullName: state.selectedSalon?.name ?? '',
                avatarUrl: state.selectedSalon?.logoUrl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.selectedSalon?.name ?? '',
                  style: AppTypography.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.content_cut,
            label: state.selectedService?.name ?? '',
          ),
          _Row(
            icon: Icons.person_outline,
            label:
                state.selectedPractitioner?.displayName ??
                "N'importe quel praticien",
          ),
          if (slot != null)
            _Row(
              icon: Icons.calendar_today_outlined,
              label: '$dateFmt à $timeFmt',
            ),
          if (!compact) ...[
            const Divider(color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.bookingTotal, style: AppTypography.h3),
                KynzaAmountWidget(
                  amountBif: state.selectedService?.priceBif ?? 0,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.body)),
        ],
      ),
    );
  }
}
