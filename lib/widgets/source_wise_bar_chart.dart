import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/report_analysis_summary_model.dart';

class SourceWiseBarChart extends StatefulWidget {
  const SourceWiseBarChart({
    super.key,
    required this.summary,
  });

  final ReportAnalysisSummaryModel summary;

  @override
  State<SourceWiseBarChart> createState() => _SourceWiseBarChartState();
}

class _SourceWiseBarChartState extends State<SourceWiseBarChart> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Calculate uncovered voters
    final uncoveredVoters = widget.summary.totalUniqueVoters - widget.summary.coveredVoters;

    // Create data entries for the bar chart
    final entries = [
      _ChartEntry('Unique\nVoters', widget.summary.totalUniqueVoters),
      _ChartEntry('Merged\nRecords', widget.summary.totalConsolidations),
      _ChartEntry('Covered\nVoters', widget.summary.coveredVoters),
      _ChartEntry('Uncovered\nVoters', uncoveredVoters),
    ];

    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    final palette = <Color>[
      Colors.blue,
      Colors.indigo,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightBlue,
      Colors.blueGrey,
    ];

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      if (_hoveredIndex != -1) {
                        setState(() {
                          _hoveredIndex = -1;
                        });
                      }
                      return;
                    }

                    final index = response.spot!.touchedBarGroupIndex;
                    if (_hoveredIndex != index) {
                      setState(() {
                        _hoveredIndex = index;
                      });
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final entry = entries[groupIndex];
                      return BarTooltipItem(
                        '${entry.label.replaceAll('\n', ' ')}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Count: ${entry.value}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final label = entries[index].label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    left: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  final isHovered = index == _hoveredIndex;
                  final isDimmed = _hoveredIndex != -1 && !isHovered;
                  final opacity = isDimmed ? 0.3 : 1.0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: palette[index % palette.length].withValues(alpha: opacity),
                        width: isHovered ? 32 : 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxValue.toDouble() * 1.2,
                          color: Colors.grey.shade100.withValues(alpha: isDimmed ? 0.5 : 1.0),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: isHovered ? [0] : [],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((entry) {
            final index = entries.indexOf(entry);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: palette[index % palette.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.label.replaceAll('\n', ' ')}: ${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChartEntry {
  const _ChartEntry(this.label, this.value);

  final String label;
  final int value;
}
