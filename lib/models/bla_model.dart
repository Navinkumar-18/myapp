class BlaModel {
  const BlaModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.ward,
  });

  final String id;
  final String name;
  final String adminId;
  final String ward;

  factory BlaModel.fromJson(Map<String, dynamic> json) {
    return BlaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      adminId: json['adminId']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
    );
  }
}
