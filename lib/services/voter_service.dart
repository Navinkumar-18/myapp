import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/voter.dart';

class VoterService {
  const VoterService({
    this.assetPath = 'assets/voters.json',
    this.fallbackAssetPaths = const <String>[
      'assets/வாக்காளர்_பட்டியல்_12_2026 .json',
    ],
  });

  final String assetPath;
  final List<String> fallbackAssetPaths;

  Future<List<Voter>> loadVoters() async {
    final primary = await _loadFromAsset(assetPath);
    if (primary.isNotEmpty) return primary;

    for (final fallback in fallbackAssetPaths) {
      final list = await _loadFromAsset(fallback);
      if (list.isNotEmpty) return list;
    }

    return const <Voter>[];
  }

  Future<List<Voter>> _loadFromAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      final rows = _extractRows(decoded);
      if (rows.isEmpty) return const <Voter>[];

      final voters = <Voter>[];
      for (final row in rows) {
        if (row is! Map) continue;

        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final voter = Voter.fromJson(Map<String, dynamic>.from(map));

        // Skip non-data rows / headers.
        if (voter.age < 18) continue;
        if (voter.name.trim().isEmpty || voter.epicId.trim().isEmpty) continue;

        final epicLower = voter.epicId.toLowerCase();
        if (epicLower.contains('epic')) continue;

        voters.add(voter);
      }

      return voters;
    } catch (_) {
      return const <Voter>[];
    }
  }

  List<dynamic> _extractRows(Object? decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      // Sometimes Excel-to-JSON exporters wrap the array inside a sheet key.
      for (final value in decoded.values) {
        if (value is List) return value;
      }
    }

    return const <dynamic>[];
  }
}

