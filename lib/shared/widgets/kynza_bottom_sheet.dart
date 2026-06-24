import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

/// Bottom-up sheet, max 85% screen height, 24dp top radius, 36x4dp handle.
Future<T?> showKynzaBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Flexible(child: builder(context)),
      ],
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
