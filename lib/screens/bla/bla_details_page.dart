import 'package:flutter/material.dart';

import '../../models/bla_model.dart';
import '../../services/json_service.dart';
import '../../widgets/day_wise_bar_chart.dart';

class BlaDetailsPage extends StatefulWidget {
  const BlaDetailsPage({
    super.key,
    required this.blaId,
  });

  final String blaId;

  @override
  State<BlaDetailsPage> createState() => _BlaDetailsPageState();
}

class _BlaDetailsPageState extends State<BlaDetailsPage> {
  late final JsonService _jsonService;
  late final Future<_BlaDetailsData> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _jsonService = JsonService.instance;
    _detailsFuture = _loadDetails();
  }

  Future<_BlaDetailsData> _loadDetails() async {
    final bla = await _jsonService.getBlaById(widget.blaId);
    final dayWiseCount = await _jsonService.getDayWiseCount(widget.blaId);
    final totalHousesCovered = dayWiseCount.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    return _BlaDetailsData(
      bla: bla,
      dayWiseCount: dayWiseCount,
      totalHousesCovered: totalHousesCovered,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLA Details'),
      ),
      body: FutureBuilder<_BlaDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load BLA details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.bla == null) {
            return const Center(child: Text('BLA not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.bla!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ward: ${data.bla!.ward}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Houses Covered: ${data.totalHousesCovered}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day-wise House Coverage',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: DayWiseBarChart(dayWiseCount: data.dayWiseCount),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BlaDetailsData {
  const _BlaDetailsData({
    required this.bla,
    required this.dayWiseCount,
    required this.totalHousesCovered,
  });

  final BlaModel? bla;
  final Map<String, int> dayWiseCount;
  final int totalHousesCovered;
}
