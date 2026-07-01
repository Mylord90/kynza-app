import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';

class KynzaLineChartSeries {
  const KynzaLineChartSeries({
    required this.spots,
    this.color = AppColors.primary,
    this.dashed = false,
  });

  final List<FlSpot> spots;
  final Color color;
  final bool dashed;
}

/// fl_chart line chart — gold line(s) on the dark surface, horizontal
/// grid lines only (surfaceVariant), JetBrains Mono BIF tooltip. Animates
/// on first render (fl_chart default).
class KynzaLineChart extends StatelessWidget {
  const KynzaLineChart({
    super.key,
    required this.title,
    required this.series,
    this.xLabels = const [],
    this.height = 220,
  });

  final String title;
  final List<KynzaLineChartSeries> series;
  final List<String> xLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final allSpots = series.expand((s) => s.spots).toList();
    final rawMax = allSpots.isEmpty
        ? 0.0
        : allSpots.fold(0.0, (m, s) => s.y > m ? s.y : m);
    final maxY = rawMax == 0 ? 1.0 : rawMax * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.surfaceVariant,
                  strokeWidth: 1,
                ),
              ),
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
                    showTitles: xLabels.isNotEmpty,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= xLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          xLabels[i],
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          CurrencyFormatter.formatBif(s.y.round()),
                          AppTypography.bodySmall.copyWith(
                            fontFamily: AppTypography.fontMono,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: series
                  .map(
                    (s) => LineChartBarData(
                      spots: s.spots,
                      isCurved: true,
                      color: s.color,
                      barWidth: 2,
                      dashArray: s.dashed ? [6, 4] : null,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: !s.dashed,
                        color: s.color.withValues(alpha: 0.08),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
