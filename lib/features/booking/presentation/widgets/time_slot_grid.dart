import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/slot_availability.dart';
import '../../../../core/models/time_slot_model.dart';
import '../../../../core/utils/haptics.dart';

class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  final List<TimeSlot> slots;
  final TimeSlot? selected;
  final void Function(TimeSlot) onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.4,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selected == slot;
        final isRare = slot.availability == SlotAvailability.rare;

        return InkWell(
          onTap: () {
            KynzaHaptics.selection();
            onSelected(slot);
          },
          borderRadius: AppRadius.md_,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: AppRadius.md_,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isRare ? AppColors.primary : AppColors.border),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:'
                  '${slot.startTime.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.h3.copyWith(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textPrimary,
                  ),
                ),
                if (isRare && !isSelected)
                  const Text(
                    'Dernière place !',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
