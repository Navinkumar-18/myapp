import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/voter.dart';
import '../services/excel_service.dart';

class VoterScreen extends StatefulWidget {
  const VoterScreen({super.key});

  @override
  State<VoterScreen> createState() => _VoterScreenState();
}

class _VoterScreenState extends State<VoterScreen> {
  late final Future<List<Voter>> _votersFuture;
  int? _touchedIndex;

  // Power BI inspired color palette
  static const List<Color> _pieColors = <Color>[
    Color(0xFF0078D4), // Azure Blue
    Color(0xFFD83B01), // Vibrant Orange
    Color(0xFF107C10), // Success Green
    Color(0xFF5C2E91), // Royal Purple
    Color(0xFFFFB900), // Golden Yellow
    Color(0xFFE81123), // Crimson Red
    Color(0xFF00B7C3), // Cyan Teal
    Color(0xFFE3008C), // Magenta Pink
  ];

  @override
  void initState() {
    super.initState();
    _votersFuture = ExcelService().loadVoters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voter Dashboard')),
      body: FutureBuilder<List<Voter>>(
        future: _votersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unable to load voter data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final voters = snapshot.data ?? const <Voter>[];
          if (voters.isEmpty) {
            return const Center(child: Text('No voter data found.'));
          }

          final genderCounts = <String, int>{};
          for (final voter in voters) {
            final key = voter.gender.trim().isEmpty
                ? 'Unknown'
                : voter.gender.trim();
            genderCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
          }

          final entries = genderCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voter Dashboard (Gender)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 0,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = null;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: List<PieChartSectionData>.generate(
                                entries.length,
                                (index) {
                                  final entry = entries[index];
                                  final isTouched = index == _touchedIndex;
                                  final opacity = _touchedIndex == null || isTouched ? 1.0 : 0.3;
                                  final color = _pieColors[index % _pieColors.length].withValues(alpha: opacity);
                                  final radius = isTouched ? 110.0 : 100.0;
                                  
                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value.toDouble(),
                                    title: entry.value.toString(),
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: isTouched ? 16 : 14,
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
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: List<Widget>.generate(entries.length, (index) {
                            final entry = entries[index];
                            final color = _pieColors[index % _pieColors.length];
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
                                const SizedBox(width: 6),
                                Text('${entry.key}: ${entry.value}'),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: voters.length,
                  itemBuilder: (context, index) {
                    final voter = voters[index];
                    return ListTile(
                      title: Text(voter.voterName),
                      subtitle: Text(
                        'House: ${voter.houseNo} | Age: ${voter.age} | Gender: ${voter.gender}',
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}