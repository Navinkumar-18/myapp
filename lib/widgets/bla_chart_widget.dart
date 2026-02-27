import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bla_report_model.dart';

class BlaChartWidget extends StatelessWidget {
  const BlaChartWidget({
    super.key,
    required this.reports,
    this.lowPerformanceThreshold = 10,
  });

  final List<BlaReportModel> reports;
  final int lowPerformanceThreshold;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('No daily report data available.'),
      );
    }

    final maxY = reports
      .map((entry) => entry.housesVisited.toDouble())
      .reduce((a, b) => a > b ? a : b);
    final chartInterval = maxY <= 10 ? 2 : 5;

    return BarChart(
      BarChartData(
        maxY: maxY < 5 ? 5 : maxY + 2,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartInterval.toDouble(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: chartInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= reports.length) {
                  return const SizedBox.shrink();
                }
                final label = DateFormat('dd MMM').format(reports[index].date);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          reports.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: reports[index].housesVisited.toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    reports[index].housesVisited < lowPerformanceThreshold
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    reports[index].housesVisited < lowPerformanceThreshold
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}