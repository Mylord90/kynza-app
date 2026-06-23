import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/haptics.dart';

class KynzaCard extends StatefulWidget {
  const KynzaCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.isFeatured = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isFeatured;
  final EdgeInsetsGeometry padding;

  @override
  State<KynzaCard> createState() => _KynzaCardState();
}

class _KynzaCardState extends State<KynzaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isSelected || widget.isFeatured;
    final borderColor = highlighted ? AppColors.primary : AppColors.border;
    final borderWidth = highlighted ? 1.5 : 1.0;
    final shadow = widget.isFeatured
        ? AppShadows.goldGlow
        : widget.isSelected
        ? const BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 16,
            offset: Offset(0, 2),
          )
        : null;

    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.onTap == null
          ? null
          : () {
              KynzaHaptics.light();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppDurations.micro,
        child: AnimatedContainer(
          duration: AppDurations.standard,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card_,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadow == null ? null : [shadow],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
