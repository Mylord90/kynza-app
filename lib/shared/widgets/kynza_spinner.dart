import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Simple spinning gold ring. No external package dependency.
class KynzaSpinner extends StatefulWidget {
  const KynzaSpinner({
    super.key,
    this.size = 20,
    this.color = AppColors.primary,
  });

  final double size;
  final Color color;

  @override
  State<KynzaSpinner> createState() => _KynzaSpinnerState();
}

class _KynzaSpinnerState extends State<KynzaSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.size * 0.12,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          backgroundColor: widget.color.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
