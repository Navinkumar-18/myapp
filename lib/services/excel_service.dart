import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/voter.dart';

class ExcelService {
  static const String _assetPath = 'assets/voters.xlsx';
  static const String _jsonAssetPath = 'assets/voters.json';
  static const List<String> _fallbackJsonAssets = <String>[
    'assets/வாக்காளர்_பட்டியல்_12_2026 .json',
  ];

  Future<List<Voter>> loadVoters() async {
    Object? excelError;

    try {
      final voters = await _loadVotersFromExcel();
      if (voters.isNotEmpty) {
        return voters;
      }
    } catch (e) {
      excelError = e;
    }

    try {
      final voters = await _loadVotersFromJson();
      if (voters.isNotEmpty) {
        return voters;
      }
      return const <Voter>[];
    } catch (jsonError) {
      throw Exception(
        'Failed to load voters from Excel and JSON. Excel: $excelError | JSON: $jsonError',
      );
    }
  }

  Future<List<Voter>> _loadVotersFromExcel() async {
    final bytes = await rootBundle.load(_assetPath);
    final excel = Excel.decodeBytes(bytes.buffer.asUint8List());

    if (excel.tables.isEmpty) {
      return const <Voter>[];
    }

    final voters = <Voter>[];

    for (final table in excel.tables.values) {
      if (table.rows.length <= 1) {
        continue;
      }

      for (final row in table.rows.skip(1)) {
        if (row.length < 7) {
          continue;
        }

        try {
          final parsedRow = List<String>.generate(
            7,
            (index) => _cellToString(index < row.length ? row[index] : null),
            growable: false,
          );

          final hasAnyValue = parsedRow.any((value) => value.trim().isNotEmpty);
          if (!hasAnyValue) {
            continue;
          }

          voters.add(Voter.fromRow(parsedRow));
        } catch (_) {
          continue;
        }
      }
    }

    return voters;
  }

  Future<List<Voter>> _loadVotersFromJson() async {
    final primary = await _loadFromJsonAsset(_jsonAssetPath);
    if (primary.isNotEmpty) return primary;

    for (final path in _fallbackJsonAssets) {
      final list = await _loadFromJsonAsset(path);
      if (list.isNotEmpty) return list;
    }

    return const <Voter>[];
  }

  Future<List<Voter>> _loadFromJsonAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return const <Voter>[];
    }

    final voters = <Voter>[];

    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }

      final map = item.map((k, v) => MapEntry(k.toString(), v));
      final voter = Voter.fromJson(Map<String, dynamic>.from(map));
      if (voter.age < 18) continue;
      if (voter.name.trim().isEmpty || voter.epicId.trim().isEmpty) continue;
      if (voter.epicId.toLowerCase().contains('epic')) continue;

      final id = map.entries
          .where((e) => e.key.contains('வாக்காளர்') || e.key.contains('serial'))
          .map((e) => _dynamicToString(e.value))
          .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');

      voters.add(
        Voter(
          id: id.trim().isEmpty ? null : id.trim(),
          name: voter.name,
          fatherName: voter.fatherName,
          houseNumber: voter.houseNumber,
          age: voter.age,
          gender: voter.gender,
          epicId: voter.epicId,
        ),
      );
    }

    return voters;
  }

  String _dynamicToString(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }

  String _cellToString(Data? cell) {
    try {
      final value = cell?.value;
      if (value == null) {
        return '';
      }

      if (value is FormulaCellValue) {
        return value.formula.toString();
      }

      return value.toString();
    } catch (_) {
      try {
        return cell?.toString() ?? '';
      } catch (_) {
        return '';
      }
    }
  }
}