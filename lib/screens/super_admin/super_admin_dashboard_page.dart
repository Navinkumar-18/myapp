import 'package:flutter/material.dart';

import '../../models/bla_model.dart';
import '../../models/report_analysis_summary_model.dart';
import '../../services/json_service.dart';
import '../../widgets/source_wise_bar_chart.dart';
import '../../widgets/top_bla_pie_chart.dart';
import '../bla/bla_details_page.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  late final JsonService _jsonService;
  late final Future<_SuperAdminData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _jsonService = JsonService.instance;
    _dashboardFuture = _loadData();
  }

  Future<_SuperAdminData> _loadData() async {
    final blas = await _jsonService.getBlas();
    final topBlas = await _jsonService.getTopConsolidatingBlas(limit: 5);
    final summary = await _jsonService.getReportAnalysisSummary();
    final sourceWiseCount = await _jsonService.getSourceWiseVoterCount();
    return _SuperAdminData(
      allBlas: blas,
      topBlas: topBlas,
      summary: summary,
      sourceWiseCount: sourceWiseCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
      ),
      body: FutureBuilder<_SuperAdminData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load dashboard data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No dashboard data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Analysis (All Assets Data)',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Unique Voters',
                                value: data.summary.totalUniqueVoters.toString(),
                              ),
                            ),
                            Expanded(
                              child: _MetricTile(
                                label: 'Merged Records',
                                value: data.summary.totalConsolidations.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Covered Voters',
                                value: data.summary.coveredVoters.toString(),
                              ),
                            ),
                            Expanded(
                              child: _MetricTile(
                                label: 'Coverage %',
                                value:
                                    '${data.summary.coveragePercentage.toStringAsFixed(1)}%',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Source-Wise Voter Distribution',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Statistical analysis of voters by data source',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SourceWiseBarChart(summary: data.summary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 5 BLAs by Merged Records',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TopBlaPieChart(topBlas: data.topBlas),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All BLAs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...data.allBlas.map(
                  (bla) => Card(
                    child: ListTile(
                      title: Text(bla.name),
                      subtitle: Text('Ward: ${bla.ward} • Admin: ${bla.adminId}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => BlaDetailsPage(blaId: bla.id),
                          ),
                        );
                      },
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

class _SuperAdminData {
  const _SuperAdminData({
    required this.allBlas,
    required this.topBlas,
    required this.summary,
    required this.sourceWiseCount,
  });

  final List<BlaModel> allBlas;
  final List<BlaTotalCount> topBlas;
  final ReportAnalysisSummaryModel summary;
  final Map<String, int> sourceWiseCount;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
