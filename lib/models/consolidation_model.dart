class ConsolidationModel {
  const ConsolidationModel({
    required this.blaId,
    required this.epicId,
    required this.date,
  });

  final String blaId;
  final String epicId;
  final String date;

  factory ConsolidationModel.fromJson(Map<String, dynamic> json) {
    return ConsolidationModel(
      blaId: json['blaId']?.toString() ?? '',
      epicId: json['epicId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}
