import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bla_report_model.dart';

class BlaService {
  BlaService({SupabaseClient? client, this.useMockData = false})
      : _client = client;

  final SupabaseClient? _client;
  final bool useMockData;
  static const String _localDatasetPath = 'assets/voters.json';
  static const List<String> _fallbackDatasetPaths = <String>[
    'assets/வாக்காளர்_பட்டியல்_12_2026 .json',
    'assets/voters.json',
  ];
  static Future<List<BlaReportModel>>? _cachedLocalReportsFuture;

  static final List<BlaReportModel> _dummyReports = <BlaReportModel>[
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 16),
      housesVisited: 8,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 17),
      housesVisited: 11,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 18),
      housesVisited: 7,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 19),
      housesVisited: 14,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 20),
      housesVisited: 10,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 21),
      housesVisited: 16,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 22),
      housesVisited: 9,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 23),
      housesVisited: 13,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 24),
      housesVisited: 12,
    ),
    BlaReportModel(
      officerId: 'OFFICER_001',
      officerName: 'Demo Officer',
      date: DateTime(2026, 2, 25),
      housesVisited: 15,
    ),
  ];

  SupabaseClient? get _supabaseClient {
    if (useMockData) {
      return null;
    }

    try {
      return _client ?? Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<BlaReportModel>> _loadLocalReports() {
    _cachedLocalReportsFuture ??= _loadLocalReportsInternal();
    return _cachedLocalReportsFuture!;
  }

  Future<List<BlaReportModel>> _loadLocalReportsInternal() async {
    try {
      final jsonString = await _loadFirstAvailableDataset();
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return _dummyReports;
      }

      final voterRows = decoded.whereType<Map>().where((row) {
        for (final entry in row.entries) {
          final key = entry.key.toString();
          if (!key.contains('வாக்காளர்') && !key.contains('serial')) continue;
          return entry.value is num;
        }
        return false;
      }).map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();

      if (voterRows.isEmpty) {
        return _dummyReports;
      }

      const dayCount = 10;
      final chunkSize = (voterRows.length / dayCount).ceil();
      final startDate = DateTime(2026, 2, 16);
      final reports = <BlaReportModel>[];

      for (var index = 0; index < dayCount; index++) {
        final start = index * chunkSize;
        if (start >= voterRows.length) {
          break;
        }

        final end = (start + chunkSize) > voterRows.length
            ? voterRows.length
            : start + chunkSize;

        reports.add(
          BlaReportModel(
            officerId: 'OFFICER_001',
            officerName: 'Demo Officer',
            date: startDate.add(Duration(days: index)),
            housesVisited: end - start,
          ),
        );
      }

      reports.sort((a, b) => a.date.compareTo(b.date));
      return reports;
    } catch (_) {
      return _dummyReports;
    }
  }

  Future<String> _loadFirstAvailableDataset() async {
    try {
      return await rootBundle.loadString(_localDatasetPath);
    } catch (_) {
      for (final path in _fallbackDatasetPaths) {
        try {
          return await rootBundle.loadString(path);
        } catch (_) {
          continue;
        }
      }
      return '[]';
    }
  }

  Future<List<BlaReportModel>> _getLocalReports({String? officerId}) async {
    final localReports = await _loadLocalReports();
    final filteredRows = officerId == null || officerId.isEmpty
        ? List<BlaReportModel>.from(localReports)
        : localReports.where((row) => row.officerId == officerId).toList();
    filteredRows.sort((a, b) => a.date.compareTo(b.date));
    return filteredRows;
  }

  Stream<List<BlaReportModel>> streamDailyReports({String? officerId}) {
    final client = _supabaseClient;
    if (client == null) {
      return Stream.fromFuture(_getLocalReports(officerId: officerId));
    }

    final baseStream = client
        .from('bla_daily_reports')
        .stream(primaryKey: ['officerId', 'date']);

    final filteredStream = officerId == null || officerId.isEmpty
        ? baseStream
        : baseStream.eq('officerId', officerId);

    return filteredStream.order('date', ascending: true).map(
      (rows) => rows
          .whereType<Map<String, dynamic>>()
          .map(BlaReportModel.fromJson)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  Future<List<BlaReportModel>> fetchDailyReports({String? officerId}) async {
    final client = _supabaseClient;
    if (client == null) {
      return _getLocalReports(officerId: officerId);
    }

    final response = await client
        .from('bla_daily_reports')
        .select('officerId, officerName, date, housesVisited')
        .order('date', ascending: true);

    final rows = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(BlaReportModel.fromJson)
        .toList();

    final filteredRows = officerId == null || officerId.isEmpty
        ? rows
        : rows.where((row) => row.officerId == officerId).toList();

    filteredRows.sort((a, b) => a.date.compareTo(b.date));
    return filteredRows;
  }

  Future<List<OfficerOption>> fetchOfficers() async {
    final client = _supabaseClient;
    if (client == null) {
      return const <OfficerOption>[
        OfficerOption(officerId: 'OFFICER_001', officerName: 'Demo Officer'),
      ];
    }

    final response = await client
        .from('bla_daily_reports')
        .select('officerId, officerName')
        .order('officerName', ascending: true);

    final rows = (response as List<dynamic>).whereType<Map<String, dynamic>>();
    final officersById = <String, OfficerOption>{};

    for (final row in rows) {
      final officerId = (row['officerId'] ?? '').toString();
      final officerName = (row['officerName'] ?? '').toString();
      if (officerId.isEmpty) {
        continue;
      }
      officersById[officerId] = OfficerOption(
        officerId: officerId,
        officerName: officerName.isEmpty ? officerId : officerName,
      );
    }

    final officers = officersById.values.toList()
      ..sort((a, b) => a.officerName.compareTo(b.officerName));
    return officers;
  }
}

class OfficerOption {
  const OfficerOption({required this.officerId, required this.officerName});

  final String officerId;
  final String officerName;
}