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
    // Power BI inspired color palette
    final palette = <Color>[
      const Color(0xFF0078D4), // Azure Blue
      const Color(0xFFD83B01), // Vibrant Orange
      const Color(0xFF107C10), // Success Green
      const Color(0xFF5C2E91), // Royal Purple
      const Color(0xFFFFB900), // Golden Yellow
      const Color(0xFFE81123), // Crimson Red
      const Color(0xFF00B7C3), // Cyan Teal
      const Color(0xFFE3008C), // Magenta Pink
    ];

    final hoveredValid = _hoveredIndex >= 0 && _hoveredIndex < widget.topBlas.length;
    final hoveredItem = hoveredValid ? widget.topBlas[_hoveredIndex] : null;
    final hoveredPercent = hoveredItem == null || total == 0
        ? 0.0
        : (hoveredItem.total / total) * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
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
                      centerSpaceRadius: 0,
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
                        final isDimmed = _hoveredIndex != -1 && !isHovered;
                        final opacity = isDimmed ? 0.3 : 1.0;
                        
                        return PieChartSectionData(
                          color: palette[index % palette.length].withValues(alpha: opacity),
                          value: item.total.toDouble(),
                          radius: isHovered ? 110 : 100,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontSize: isHovered ? 15 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                              ),
                            ],
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
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.topBlas.length, (index) {
              final item = widget.topBlas[index];
              final isHovered = index == _hoveredIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: isHovered ? 12 : 10,
                      height: isHovered ? 12 : 10,
                      decoration: BoxDecoration(
                        color: palette[index % palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.bla.name} (${item.total})',
                        style: isHovered
                            ? Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700)
                            : Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
