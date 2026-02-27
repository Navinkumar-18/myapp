import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DayWiseBarChart extends StatelessWidget {
  const DayWiseBarChart({
    super.key,
    required this.dayWiseCount,
  });

  final Map<String, int> dayWiseCount;

  @override
  Widget build(BuildContext context) {
    if (dayWiseCount.isEmpty) {
      return const Center(
        child: Text('No coverage data available'),
      );
    }

    final entries = dayWiseCount.entries.toList(growable: false);
    final maxY = entries
        .map((entry) => entry.value)
        .fold<int>(0, (previous, current) => current > previous ? current : previous)
        .toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthPerBar = constraints.maxWidth / entries.length;
        final barWidth = widthPerBar.clamp(20, 44).toDouble();

        return BarChart(
          BarChartData(
            maxY: maxY == 0 ? 4 : maxY + 2,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${entries[index].value}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }

                    final date = entries[index].key;
                    final parts = date.split('-');
                    final label = parts.length == 3
                        ? '${parts[2]}/${parts[1]}'
                        : date;

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List<BarChartGroupData>.generate(
              entries.length,
              (index) {
                final value = entries[index].value.toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      width: barWidth,
                      color: Colors.green,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
