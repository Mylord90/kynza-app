import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class BarData {
  const BarData({required this.label, required this.value});

  final String label;
  final int value;
}

/// Pure Flutter `CustomPainter` bar chart — no chart package dependency
/// (kynza-flutter-architecture.md). Bars grow from 0 on first render.
class KynzaSimpleBarChart extends StatefulWidget {
  const KynzaSimpleBarChart({
    super.key,
    required this.title,
    required this.bars,
    this.height = 180,
  });

  final String title;
  final List<BarData> bars;
  final double height;

  @override
  State<KynzaSimpleBarChart> createState() => _KynzaSimpleBarChartState();
}

class _KynzaSimpleBarChartState extends State<KynzaSimpleBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.bars.fold(
      1,
      (max, b) => b.value > max ? b.value : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _BarChartPainter(
                bars: widget.bars,
                maxValue: maxValue,
                progress: Curves.easeOut.transform(_controller.value),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.bars,
    required this.maxValue,
    required this.progress,
  });

  final List<BarData> bars;
  final int maxValue;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    const labelHeight = 18.0;
    const valueHeight = 16.0;
    final chartHeight = size.height - labelHeight - valueHeight;
    final slotWidth = size.width / bars.length;
    final barWidth = (slotWidth * 0.5).clamp(8.0, 32.0);

    final barPaint = Paint()..color = AppColors.primary;

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final centerX = slotWidth * i + slotWidth / 2;
      final barHeight = maxValue == 0
          ? 0.0
          : (bar.value / maxValue) * chartHeight * progress;

      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        valueHeight + (chartHeight - barHeight),
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        barPaint,
      );

      if (progress > 0.6) {
        final valueText = TextPainter(
          text: TextSpan(
            text: '${bar.value}',
            style: AppTypography.bodySmall.copyWith(fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valueText.paint(
          canvas,
          Offset(
            centerX - valueText.width / 2,
            valueHeight + (chartHeight - barHeight) - valueText.height - 2,
          ),
        );
      }

      final labelText = TextPainter(
        text: TextSpan(
          text: bar.label,
          style: AppTypography.bodySmall.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slotWidth);
      labelText.paint(
        canvas,
        Offset(centerX - labelText.width / 2, size.height - labelHeight + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bars != bars;
}
