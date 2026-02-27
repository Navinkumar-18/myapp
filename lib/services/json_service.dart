import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bla_model.dart';
import '../models/consolidation_model.dart';
import '../models/report_analysis_summary_model.dart';

class JsonService {
  JsonService._();

  static final JsonService instance = JsonService._();

  static const String _assetPath = 'assets/data.json';
  static const List<String> _analysisAssetPaths = <String>[
    'assets/data.json',
    'assets/voters.json',
    'assets/வாக்காளர்_பட்டியல்_12_2026 .json',
    'assets/வாக்காளர்_பட்டியல்_165_2026.json',
    'assets/வாக்காளர்_பட்டியல்_166_2026.json',
    'assets/வாக்காளர்_பட்டியல்_167_2026.json',
    'assets/வாக்காளர்_பட்டியல்_168_2026.json',
  ];

  bool _isLoaded = false;
  List<BlaModel> _blas = const <BlaModel>[];
  List<ConsolidationModel> _consolidations = const <ConsolidationModel>[];
  List<AssetVoterRecord> _assetVoters = const <AssetVoterRecord>[];
  Map<String, int> _sourceVoterCounts = const <String, int>{};

  Future<void> _loadData() async {
    if (_isLoaded) {
      return;
    }

    final rawJson = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

    final blaJson = (decoded['blas'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final consolidationJson =
        (decoded['consolidations'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    _blas = blaJson.map(BlaModel.fromJson).toList(growable: false);
    _consolidations = consolidationJson
        .map(ConsolidationModel.fromJson)
        .toList(growable: false);
    await _loadAllAssetVoters(decoded);

    _isLoaded = true;
  }

  Future<void> _loadAllAssetVoters(Map<String, dynamic> mainData) async {
    final voterByEpic = <String, AssetVoterRecord>{};
    final sourceCounts = <String, int>{};

    void collectVoter({
      required String source,
      required String epicId,
      String? ward,
    }) {
      final normalizedEpic = epicId.trim();
      if (normalizedEpic.isEmpty) {
        return;
      }

      sourceCounts.update(source, (value) => value + 1, ifAbsent: () => 1);

      final existing = voterByEpic[normalizedEpic];
      if (existing == null) {
        voterByEpic[normalizedEpic] = AssetVoterRecord(
          epicId: normalizedEpic,
          ward: ward?.trim().isEmpty == true ? null : ward?.trim(),
          source: source,
        );
        return;
      }

      final nextWard =
          (existing.ward == null || existing.ward!.trim().isEmpty)
              ? (ward?.trim().isEmpty == true ? null : ward?.trim())
              : existing.ward;

      voterByEpic[normalizedEpic] = existing.copyWith(ward: nextWard);
    }

    final mainVoters =
        (mainData['voters'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>();

    for (final item in mainVoters) {
      collectVoter(
        source: 'assets/data.json',
        epicId: _asString(item['epicId']),
        ward: _asString(item['ward']),
      );
    }

    for (final assetPath in _analysisAssetPaths) {
      if (assetPath == _assetPath) {
        continue;
      }

      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);

      if (decoded is! List<dynamic>) {
        continue;
      }

      for (final row in decoded.whereType<Map<String, dynamic>>()) {
        final epicId = _extractEpicId(row);
        if (epicId.isEmpty) {
          continue;
        }

        if (_isHeaderValue(epicId)) {
          continue;
        }

        collectVoter(
          source: assetPath,
          epicId: epicId,
          ward: _asString(row['ward']),
        );
      }
    }

    _assetVoters = voterByEpic.values.toList(growable: false);
    _sourceVoterCounts = Map<String, int>.unmodifiable(sourceCounts);
  }

  String _extractEpicId(Map<String, dynamic> row) {
    return _asString(
      row['epicId'] ?? row['Column7'] ?? row['__EMPTY_5'] ?? row['EPIC'],
    );
  }

  bool _isHeaderValue(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'EPIC' ||
        normalized.contains('EPIC எண்'.toUpperCase()) ||
        normalized.contains('EPIC NO') ||
        normalized.contains('EPIC ID');
  }

  String _asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  Future<List<BlaModel>> getBlas() async {
    await _loadData();
    return List<BlaModel>.unmodifiable(_blas);
  }

  Future<BlaModel?> getBlaById(String blaId) async {
    await _loadData();
    for (final bla in _blas) {
      if (bla.id == blaId) {
        return bla;
      }
    }
    return null;
  }

  Future<List<ConsolidationModel>> getConsolidationsByBla(String blaId) async {
    await _loadData();
    return _consolidations
        .where((item) => item.blaId == blaId)
        .toList(growable: false);
  }

  Future<Map<String, int>> getDayWiseCount(String blaId) async {
    final consolidations = await getConsolidationsByBla(blaId);

    final countByDate = <String, int>{};
    for (final entry in consolidations) {
      countByDate.update(entry.date, (value) => value + 1, ifAbsent: () => 1);
    }

    final sortedDates = countByDate.keys.toList(growable: false)..sort();

    final sortedResult = <String, int>{};
    for (final date in sortedDates) {
      sortedResult[date] = countByDate[date] ?? 0;
    }
    return sortedResult;
  }

  Future<Map<String, int>> getConsolidationTotalsByBla() async {
    await _loadData();

    final totals = <String, int>{};
    for (final item in _consolidations) {
      totals.update(item.blaId, (value) => value + 1, ifAbsent: () => 1);
    }
    return totals;
  }

  Future<List<BlaTotalCount>> getTopConsolidatingBlas({int limit = 5}) async {
    await _loadData();

    final totals = await getConsolidationTotalsByBla();
    final entries = _blas
        .map(
          (bla) => BlaTotalCount(
            bla: bla,
            total: totals[bla.id] ?? 0,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.total.compareTo(a.total));

    final safeLimit = limit < 0 ? 0 : limit;
    if (entries.length <= safeLimit) {
      return entries;
    }
    return entries.take(safeLimit).toList(growable: false);
  }

  Future<List<AssetVoterRecord>> getAllAssetVoters() async {
    await _loadData();
    return List<AssetVoterRecord>.unmodifiable(_assetVoters);
  }

  Future<Map<String, int>> getSourceWiseVoterCount() async {
    await _loadData();

    final sortedKeys = _sourceVoterCounts.keys.toList(growable: false)..sort();
    final sortedMap = <String, int>{};
    for (final key in sortedKeys) {
      sortedMap[key] = _sourceVoterCounts[key] ?? 0;
    }
    return sortedMap;
  }

  Future<ReportAnalysisSummaryModel> getReportAnalysisSummary() async {
    await _loadData();

    final totalUniqueVoters = _assetVoters.length;
    final totalConsolidations = _consolidations.length;

    final consolidatedEpics = _consolidations
        .map((item) => item.epicId.trim())
        .where((epic) => epic.isNotEmpty)
        .toSet();

    final coveredVoters = _assetVoters
        .where((item) => consolidatedEpics.contains(item.epicId))
        .length;

    final coveragePercentage = totalUniqueVoters == 0
        ? 0.0
        : (coveredVoters / totalUniqueVoters) * 100;

    return ReportAnalysisSummaryModel(
      totalUniqueVoters: totalUniqueVoters,
      totalConsolidations: totalConsolidations,
      coveredVoters: coveredVoters,
      coveragePercentage: coveragePercentage,
    );
  }
}

class BlaTotalCount {
  const BlaTotalCount({
    required this.bla,
    required this.total,
  });

  final BlaModel bla;
  final int total;
}
