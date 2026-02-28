import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/voter.dart';

class VoterChartsWidget extends StatelessWidget {
  const VoterChartsWidget({super.key, required this.voters});

  final List<Voter> voters;

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) {
      return const Center(child: Text('No voter data available.'));
    }

    final maleCount = voters.where((v) => _isMale(v.gender)).length;
    final femaleCount = voters.where((v) => _isFemale(v.gender)).length;
    final unknownCount = voters.length - maleCount - femaleCount;

    final theme = Theme.of(context);
    final maleColor = theme.colorScheme.primary;
    final femaleColor = theme.colorScheme.tertiary;
    final unknownColor = theme.colorScheme.outline.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: [
                      _pieSection(
                        color: maleColor,
                        value: maleCount.toDouble(),
                        title: maleCount == 0 ? '' : maleCount.toString(),
                      ),
                      _pieSection(
                        color: femaleColor,
                        value: femaleCount.toDouble(),
                        title: femaleCount == 0 ? '' : femaleCount.toString(),
                      ),
                      if (unknownCount > 0)
                        _pieSection(
                          color: unknownColor,
                          value: unknownCount.toDouble(),
                          title: unknownCount.toString(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Legend(
                items: [
                  _LegendItem(label: 'Male', color: maleColor, value: maleCount),
                  _LegendItem(
                    label: 'Female',
                    color: femaleColor,
                    value: femaleCount,
                  ),
                  if (unknownCount > 0)
                    _LegendItem(
                      label: 'Unknown',
                      color: unknownColor,
                      value: unknownCount,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Age distribution',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: BarChart(_ageDistributionChart(context)),
        ),
      ],
    );
  }

  PieChartSectionData _pieSection({
    required Color color,
    required double value,
    required String title,
  }) {
    return PieChartSectionData(
      color: color,
      value: value <= 0 ? 0.0001 : value,
      title: title,
      radius: 70,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  BarChartData _ageDistributionChart(BuildContext context) {
    final theme = Theme.of(context);

    final bins = <({String label, bool Function(int age) match})>[
      (label: '18–25', match: (age) => age >= 18 && age <= 25),
      (label: '26–35', match: (age) => age >= 26 && age <= 35),
      (label: '36–45', match: (age) => age >= 36 && age <= 45),
      (label: '46–60', match: (age) => age >= 46 && age <= 60),
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

    return BarChartData(
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    );
  }

  bool _isMale(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'm' ||
        v.contains('male') ||
        raw.contains('ஆண்') ||
        raw.contains('पुरुष');
  }

  bool _isFemale(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'f' ||
        v.contains('female') ||
        raw.contains('பெண்') ||
        raw.contains('महिला');
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.label}: ${item.value}'),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LegendItem {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final int value;
}

