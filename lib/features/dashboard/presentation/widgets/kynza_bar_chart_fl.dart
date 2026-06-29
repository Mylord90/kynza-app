import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import 'kynza_simple_bar_chart.dart' show BarData;

/// fl_chart bar chart — gold bars, rounded top corners, touch tooltip.
/// Takes the same [BarData] shape as [KynzaSimpleBarChart] (the custom
/// CustomPainter variant) so callers can pick either without reshaping
/// data.
class KynzaBarChartFl extends StatelessWidget {
  const KynzaBarChartFl({
    super.key,
    required this.title,
    required this.bars,
    this.height = 200,
  });

  final String title;
  final List<BarData> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold(1, (m, b) => b.value > m ? b.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.2,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.surfaceVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          bars[i].label,
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        '${rod.toY.round()}',
                        AppTypography.bodySmall.copyWith(
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.primary,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].value.toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
