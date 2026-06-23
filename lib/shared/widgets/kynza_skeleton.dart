import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_spacing.dart';

/// Shimmering placeholder block. Native AnimationController — no external
/// shimmer package dependency.
class KynzaSkeleton extends StatefulWidget {
  const KynzaSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
    this.isRound = false,
    this.count = 1,
  });

  final double? width;
  final double height;
  final double radius;
  final bool isRound;
  final int count;

  @override
  State<KynzaSkeleton> createState() => _KynzaSkeletonState();
}

class _KynzaSkeletonState extends State<KynzaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar() {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.surface,
            AppColors.surfaceVariant,
            _opacity.value,
          ),
          borderRadius: widget.isRound
              ? BorderRadius.circular(widget.height / 2)
              : BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 1) return _bar();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _bar(),
        ],
      ],
    );
  }
}
