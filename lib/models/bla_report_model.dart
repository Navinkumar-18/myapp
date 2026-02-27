class BlaReportModel {
  const BlaReportModel({
    required this.officerId,
    required this.officerName,
    required this.date,
    required this.housesVisited,
  });

  final String officerId;
  final String officerName;
  final DateTime date;
  final int housesVisited;

  factory BlaReportModel.fromJson(Map<String, dynamic> json) {
    return BlaReportModel(
      officerId: (json['officerId'] ?? '').toString(),
      officerName: (json['officerName'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      housesVisited: _toInt(json['housesVisited']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}