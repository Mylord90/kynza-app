import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';
import 'kynza_button.dart';

/// Mandatory confirmation modal before any destructive action (R15).
/// The only exception is Staff's [Confirmer arrivée] button (R10), which
/// must never call this.
Future<bool> showKynzaConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg_),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTypography.body),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: KynzaButton(
                      label: cancelLabel ?? l10n.commonCancel,
                      variant: KynzaButtonVariant.ghost,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: KynzaButton(
                      label: confirmLabel ?? l10n.commonConfirm,
                      variant: isDestructive
                          ? KynzaButtonVariant.destructive
                          : KynzaButtonVariant.primary,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
