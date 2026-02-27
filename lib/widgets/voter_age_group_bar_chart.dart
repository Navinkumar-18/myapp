import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/voter.dart';

class VoterAgeGroupBarChart extends StatelessWidget {
  const VoterAgeGroupBarChart({
    super.key,
    required this.voters,
  });

  final List<Voter> voters;

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) {
      return const Center(child: Text('No data for selected filters.'));
    }

    final theme = Theme.of(context);

    final bins = <({String label, bool Function(int age) match})>[
      (label: '18–25', match: (age) => age >= 18 && age <= 25),
      (label: '26–40', match: (age) => age >= 26 && age <= 40),
      (label: '41–60', match: (age) => age >= 41 && age <= 60),
      (label: '60+', match: (age) => age >= 61),
    ];

    final counts = List<int>.filled(bins.length, 0);
    for (final voter in voters) {
      final age = voter.age;
      for (var i = 0; i < bins.length; i++) {
        if (bins[i].match(age)) {
          counts[i]++;
          break;
        }
      }
    }

    final maxY = counts.isEmpty
        ? 0.0
        : counts.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b);
    final interval = maxY <= 10 ? 2.0 : 5.0;

    return BarChart(
      BarChartData(
        maxY: maxY < 5 ? 5 : maxY + 2,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= bins.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    bins[index].label,
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(
          bins.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: counts[index].toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
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

