import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/availability_exception_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class ExceptionListTile extends StatelessWidget {
  const ExceptionListTile({
    super.key,
    required this.exception,
    required this.onDelete,
  });

  final AvailabilityExceptionModel exception;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isClosure = exception.isClosed;
    return KynzaCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: isClosure ? AppColors.error : AppColors.success,
              borderRadius: AppRadius.xs_,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exception.label, style: AppTypography.h3),
                Text(
                  exception.isMultiDay
                      ? '${_fmtDate(exception.startDate)} – ${_fmtDate(exception.endDate)}'
                      : _fmtDate(exception.startDate),
                  style: AppTypography.bodySmall,
                ),
                Text(exception.typeLabel, style: AppTypography.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
