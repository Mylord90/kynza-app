import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'kynza_widgets.dart';

/// 3 concentric gold circles expanding outward + center spinner.
/// NEVER Lottie here (R13 — Moto G06 RAM constraint).
class RadarPulseWidget extends StatefulWidget {
  const RadarPulseWidget({
    super.key,
    required this.secondsRemaining,
    this.message,
  });

  final int secondsRemaining;
  final String? message;

  @override
  State<RadarPulseWidget> createState() => _RadarPulseWidgetState();
}

class _RadarPulseWidgetState extends State<RadarPulseWidget>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                for (final delay in [0.0, 0.33, 0.66]) _ring(delay),
                const KynzaLoader(
                  size: KynzaLoaderSize.medium,
                  variant: KynzaLoaderVariant.pulse,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${widget.secondsRemaining}s',
          style: AppTypography.amount.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.message ?? context.l10n.paymentRadarWaitMessage,
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _ring(double delay) {
    final t = (_controller.value + delay) % 1.0;
    return Opacity(
      opacity: (1 - t).clamp(0.0, 0.6),
      child: Container(
        width: 40 + t * 120,
        height: 40 + t * 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
