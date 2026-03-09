import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/weight_entry_model.dart';

class WeightProgressChart extends StatelessWidget {
  final List<WeightEntryModel> entries;
  final double? goalWeight;

  const WeightProgressChart({
    super.key,
    required this.entries,
    this.goalWeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (entries.isEmpty) {
      return _emptyState(colorScheme, textTheme);
    }

    final sortedEntries = List<WeightEntryModel>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weights = sortedEntries.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxW - minW) * 0.15;
    final yMin = (minW - padding - 1).floorToDouble();
    final yMax = (maxW + padding + 1).ceilToDouble();

    final firstWeight = sortedEntries.first.weight;
    final lastWeight = sortedEntries.last.weight;
    final diff = lastWeight - firstWeight;
    final diffText = diff >= 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
    final diffColor = diff < 0 ? Colors.green : (diff > 0 ? Colors.orange : colorScheme.outline);

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].weight));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lastWeight.toStringAsFixed(1)} kg',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Current weight',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$diffText kg',
                style: textTheme.labelMedium?.copyWith(
                  color: diffColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (goalWeight != null) ...[
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${goalWeight!.toStringAsFixed(1)} kg',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    'Goal',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calcInterval(yMax - yMin),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _calcInterval(yMax - yMin),
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.toStringAsFixed(0),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _calcBottomInterval(sortedEntries.length),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      final dt = sortedEntries[idx].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${dt.day}/${dt.month}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final idx = spot.spotIndex;
                      final entry = sortedEntries[idx];
                      final dt = entry.date;
                      return LineTooltipItem(
                        '${entry.weight.toStringAsFixed(1)} kg\n${dt.day}/${dt.month}/${dt.year}',
                        TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: colorScheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.25),
                        colorScheme.primary.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                if (goalWeight != null)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, goalWeight!),
                      FlSpot((sortedEntries.length - 1).toDouble(), goalWeight!),
                    ],
                    isCurved: false,
                    color: colorScheme.tertiary.withValues(alpha: 0.5),
                    barWidth: 1.5,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        if (sortedEntries.length >= 2) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'First: ${firstWeight.toStringAsFixed(1)} kg',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              Text(
                '${sortedEntries.length} records',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              Text(
                'Latest: ${lastWeight.toStringAsFixed(1)} kg',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ],
      ],
    );
  }

  double _calcInterval(double range) {
    if (range <= 5) return 1;
    if (range <= 15) return 2;
    if (range <= 30) return 5;
    return 10;
  }

  double _calcBottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return (count / 6).ceilToDouble();
  }

  Widget _emptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No weight records yet',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start logging your weight to see your progress chart.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
