import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class KynzaPieSlice {
  const KynzaPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// fl_chart donut chart — legend below, no labels on the slices
/// themselves (legend carries the label + percentage instead).
class KynzaPieChart extends StatelessWidget {
  const KynzaPieChart({super.key, required this.slices, this.size = 180});

  final List<KynzaPieSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold(0.0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: size / 3.2,
              sectionsSpace: 2,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.value,
                    color: slice.color,
                    showTitle: false,
                    radius: size / 4,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final slice in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${slice.label} (${total == 0 ? 0 : (slice.value / total * 100).round()}%)',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
