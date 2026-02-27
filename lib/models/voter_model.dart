class VoterModel {
  final String name;
  final String fatherName;
  final String booth;
  final int age;
  final String gender;
  final String voterId;

  VoterModel({
    required this.name,
    required this.fatherName,
    required this.booth,
    required this.age,
    required this.gender,
    required this.voterId,
  });

  /// Parse voter from JSON object
  factory VoterModel.fromJson(Map<String, dynamic> json) {
    return VoterModel(
      name: json['__EMPTY']?.toString() ?? 'N/A',
      fatherName: json['__EMPTY_1']?.toString() ?? 'N/A',
      booth: json['__EMPTY_2']?.toString() ?? 'N/A',
      age: int.tryParse(json['__EMPTY_3']?.toString() ?? '0') ?? 0,
      gender: json['__EMPTY_4']?.toString() ?? 'N/A',
      voterId: json['__EMPTY_5']?.toString() ?? 'N/A',
    );
  }

  @override
  String toString() => 'Voter(name: $name, age: $age, gender: $gender)';
}
