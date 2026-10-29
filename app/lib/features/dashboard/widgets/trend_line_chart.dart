import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/dashboard_model.dart';

class TrendLineChart extends StatelessWidget {
  final List<DashboardTrendPoint> trend;

  const TrendLineChart({
    super.key,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const SizedBox.shrink();
    }

    final t1Spots = <FlSpot>[];
    final t2Spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < trend.length; i++) {
      final p = trend[i];
      final dayNum = (i + 1).toDouble();
      t1Spots.add(FlSpot(dayNum, p.total1));
      t2Spots.add(FlSpot(dayNum, p.total2));

      if (p.total2 > maxY) maxY = p.total2;
      if (p.total1 > maxY) maxY = p.total1;
    }

    if (maxY == 0) maxY = 1000;
    // Add 15% headroom
    maxY = maxY * 1.15;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Revenue Trend',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendDot(AppTheme.primary, 'Total 1'),
                    const SizedBox(width: 12),
                    _buildLegendDot(AppTheme.secondary, 'Total 2'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Line chart
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: trend.length.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (val) => const FlLine(
                      color: AppTheme.border,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (val, meta) {
                          if (val < 1 || val > trend.length) return const SizedBox.shrink();
                          return Text(
                            val.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: maxY / 3,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(
                            CurrencyFormatter.formatCompact(val),
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Total 1 Line
                    LineChartBarData(
                      spots: t1Spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 0,
                      color: AppTheme.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                    // Total 2 Line
                    LineChartBarData(
                      spots: t2Spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 0,
                      color: AppTheme.secondary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.secondary.withValues(alpha: 0.08),
                        applyCutOffY: true,
                        cutOffY: 0,
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isT1 = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isT1 ? 'Total 1' : 'Total 2'}: ${CurrencyFormatter.format(spot.y)}',
                            TextStyle(
                              color: isT1 ? const Color(0xFFE9D5FF) : const Color(0xFFD9F99D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

