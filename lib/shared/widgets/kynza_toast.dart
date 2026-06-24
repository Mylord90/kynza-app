import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum ToastLevel { success, error, warning, info }

/// error level never auto-dismisses (R04 — user must register the failure).
void showKynzaToast(
  BuildContext context, {
  required String message,
  ToastLevel level = ToastLevel.info,
}) {
  final (color, icon, duration) = switch (level) {
    ToastLevel.success => (
      AppColors.success,
      Icons.check_circle,
      const Duration(seconds: 2),
    ),
    ToastLevel.error => (
      AppColors.error,
      Icons.error_outline,
      const Duration(seconds: 4),
    ),
    ToastLevel.warning => (
      AppColors.warning,
      Icons.warning_amber_rounded,
      const Duration(seconds: 3),
    ),
    ToastLevel.info => (
      AppColors.info,
      Icons.info_outline,
      const Duration(seconds: 2),
    ),
  };

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md_),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}
