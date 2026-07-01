import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/haptics.dart';
import 'loader/widgets/loader_button.dart';

enum KynzaButtonVariant { primary, secondary, ghost, destructive }

class KynzaButton extends StatefulWidget {
  const KynzaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = KynzaButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final KynzaButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;

  @override
  State<KynzaButton> createState() => _KynzaButtonState();
}

class _KynzaButtonState extends State<KynzaButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool value) {
    if (_disabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = switch (widget.variant) {
      KynzaButtonVariant.primary => AppColors.background,
      KynzaButtonVariant.secondary => AppColors.primary,
      KynzaButtonVariant.ghost => AppColors.textSecondary,
      KynzaButtonVariant.destructive => AppColors.error,
    };

    Decoration decoration;
    switch (widget.variant) {
      case KynzaButtonVariant.primary:
        decoration = const BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        );
        break;
      case KynzaButtonVariant.secondary:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.button_,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
        break;
      case KynzaButtonVariant.ghost:
        decoration = const BoxDecoration(color: Colors.transparent);
        break;
      case KynzaButtonVariant.destructive:
        decoration = BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: AppRadius.button_,
          border: Border.all(color: AppColors.error, width: 1),
        );
        break;
    }

    final content = widget.isLoading
        ? KynzaLoaderButton(
            onGoldBackground: widget.variant == KynzaButtonVariant.primary,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTypography.button.copyWith(color: textColor),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _disabled
          ? null
          : () {
              KynzaHaptics.light();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.micro,
        child: AnimatedOpacity(
          opacity: _disabled && !widget.isLoading ? 0.5 : 1,
          duration: AppDurations.fast,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: decoration,
            child: content,
          ),
        ),
      ),
    );
  }
}
