import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/json_service.dart';

class TopBlaPieChart extends StatefulWidget {
  const TopBlaPieChart({
    super.key,
    required this.topBlas,
  });

  final List<BlaTotalCount> topBlas;

  @override
  State<TopBlaPieChart> createState() => _TopBlaPieChartState();
}

class _TopBlaPieChartState extends State<TopBlaPieChart> {
  int _hoveredIndex = -1;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    if (widget.topBlas.isEmpty) {
      return const Center(
        child: Text('No consolidation data available'),
      );
    }

    final total =
        widget.topBlas.fold<int>(0, (sum, item) => sum + item.total);
    final palette = <Color>[
      Colors.green,
      Colors.teal,
      Colors.lightGreen,
      Colors.greenAccent,
      Colors.lime,
    ];

    final hoveredValid = _hoveredIndex >= 0 && _hoveredIndex < widget.topBlas.length;
    final hoveredItem = hoveredValid ? widget.topBlas[_hoveredIndex] : null;
    final hoveredPercent = hoveredItem == null || total == 0
        ? 0.0
        : (hoveredItem.total / total) * 100;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasPopup = hoveredItem != null && _hoverPosition != null;
              final left = hasPopup
                  ? (_hoverPosition!.dx + 12)
                    .clamp(8.0, constraints.maxWidth - 190.0)
                  : 0.0;
              final top = hasPopup
                  ? (_hoverPosition!.dy - 44).clamp(8.0, 220.0 - 44.0)
                  : 0.0;

              return Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            if (_hoveredIndex != -1 || _hoverPosition != null) {
                              setState(() {
                                _hoveredIndex = -1;
                                _hoverPosition = null;
                              });
                            }
                            return;
                          }

                          final index = response.touchedSection!.touchedSectionIndex;
                          final position = event.localPosition;
                          if (_hoveredIndex != index || _hoverPosition != position) {
                            setState(() {
                              _hoveredIndex = index;
                              _hoverPosition = position;
                            });
                          }
                        },
                      ),
                      sections: List<PieChartSectionData>.generate(
                          widget.topBlas.length, (index) {
                        final item = widget.topBlas[index];
                        final percent =
                            total == 0 ? 0.0 : (item.total / total) * 100;
                        final isHovered = index == _hoveredIndex;
                        return PieChartSectionData(
                          color: palette[index % palette.length],
                          value: item.total.toDouble(),
                          radius: isHovered ? 72 : 64,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontSize: isHovered ? 13 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                  if (hasPopup)
                    Positioned(
                      left: left,
                      top: top,
                      child: IgnorePointer(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              '${hoveredItem.bla.name} • ${hoveredItem.total} • ${hoveredPercent.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List<Widget>.generate(widget.topBlas.length, (index) {
            final item = widget.topBlas[index];
            final isHovered = index == _hoveredIndex;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isHovered ? 12 : 10,
                  height: isHovered ? 12 : 10,
                  decoration: BoxDecoration(
                    color: palette[index % palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.bla.name} (${item.total})',
                  style: isHovered
                      ? Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)
                      : null,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
