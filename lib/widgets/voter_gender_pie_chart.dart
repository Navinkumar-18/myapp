import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/voter.dart';

class VoterGenderPieChart extends StatelessWidget {
  const VoterGenderPieChart({
    super.key,
    required this.voters,
  });

  final List<Voter> voters;

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) {
      return const Center(child: Text('No data for selected filters.'));
    }

    final maleCount = voters.where((v) => _isMale(v.gender)).length;
    final femaleCount = voters.where((v) => _isFemale(v.gender)).length;
    final othersCount = voters.length - maleCount - femaleCount;

    final theme = Theme.of(context);

    final maleColor = theme.colorScheme.primary;
    final femaleColor = theme.colorScheme.tertiary;
    final othersColor = theme.colorScheme.outline.withValues(alpha: 0.5);

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        color: maleColor,
        value: maleCount <= 0 ? 0.0001 : maleCount.toDouble(),
        title: maleCount == 0 ? '' : maleCount.toString(),
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: femaleColor,
        value: femaleCount <= 0 ? 0.0001 : femaleCount.toDouble(),
        title: femaleCount == 0 ? '' : femaleCount.toString(),
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      if (othersCount > 0)
        PieChartSectionData(
          color: othersColor,
          value: othersCount.toDouble(),
          title: othersCount.toString(),
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendDot(
              color: maleColor,
              label: 'Male',
              value: maleCount,
            ),
            const SizedBox(height: 8),
            _LegendDot(
              color: femaleColor,
              label: 'Female',
              value: femaleCount,
            ),
            if (othersCount > 0) ...[
              const SizedBox(height: 8),
              _LegendDot(
                color: othersColor,
                label: 'Others',
                value: othersCount,
              ),
            ],
          ],
        ),
      ],
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $value'),
      ],
    );
  }
}

