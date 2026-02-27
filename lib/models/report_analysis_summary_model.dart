class AssetVoterRecord {
  const AssetVoterRecord({
    required this.epicId,
    required this.source,
    this.ward,
  });

  final String epicId;
  final String? ward;
  final String source;

  AssetVoterRecord copyWith({
    String? epicId,
    String? ward,
    String? source,
  }) {
    return AssetVoterRecord(
      epicId: epicId ?? this.epicId,
      ward: ward ?? this.ward,
      source: source ?? this.source,
    );
  }
}

class ReportAnalysisSummaryModel {
  const ReportAnalysisSummaryModel({
    required this.totalUniqueVoters,
    required this.totalConsolidations,
    required this.coveredVoters,
    required this.coveragePercentage,
  });

  final int totalUniqueVoters;
  final int totalConsolidations;
  final int coveredVoters;
  final double coveragePercentage;
}
