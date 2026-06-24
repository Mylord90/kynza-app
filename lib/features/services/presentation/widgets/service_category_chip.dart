import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class ServiceCategoryChip extends StatelessWidget {
  const ServiceCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: AppTypography.body.copyWith(
        color: isSelected ? AppColors.background : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
