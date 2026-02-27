class Voter {
  const Voter({
    this.id,
    required this.name,
    required this.fatherName,
    required this.houseNumber,
    required this.age,
    required this.gender,
    required this.epicId,
  });

  /// Optional serial / voter ID from the roll.
  final String? id;

  /// Voter name.
  final String name;

  /// Father / husband name.
  final String fatherName;

  /// House number / door number.
  final String houseNumber;

  /// Age in years.
  final int age;

  /// Gender label (Tamil / English / short code).
  final String gender;

  /// EPIC ID.
  final String epicId;

  /// Factory used by the service to parse JSON rows coming
  /// from different asset formats (Tamil Excel export, etc.).
  factory Voter.fromJson(Map<String, dynamic> json) {
    // Primary keys used by the cleaned voters.json, with
    // graceful fallbacks to the Tamil Excel-export style keys.
    final name = _dynamicToString(
      json['name'] ?? json['__EMPTY'] ?? json['Column2'],
    ).trim();

    final fatherName = _dynamicToString(
      json['fatherName'] ?? json['guardianName'] ?? json['__EMPTY_1'] ?? json['Column3'],
    ).trim();

    final houseNumber = _dynamicToString(
      json['houseNumber'] ?? json['houseNo'] ?? json['__EMPTY_2'] ?? json['Column4'],
    ).trim();

    final age = _dynamicToInt(
      json['age'] ?? json['__EMPTY_3'] ?? json['Column5'],
    );

    final gender = _dynamicToString(
      json['gender'] ?? json['__EMPTY_4'] ?? json['Column6'],
    ).trim();

    final epicId = _dynamicToString(
      json['epicId'] ?? json['__EMPTY_5'] ?? json['Column7'],
    ).trim();

    return Voter(
      name: name,
      fatherName: fatherName,
      houseNumber: houseNumber,
      age: age,
      gender: gender,
      epicId: epicId,
    );
  }

  /// Factory to build a voter from a 7-column Excel row.
  /// Expected order: [id, name, fatherName, houseNumber, age, gender, epicId].
  factory Voter.fromRow(List<String> row) {
    final safe = List<String>.generate(
      7,
      (index) => index < row.length ? row[index] : '',
      growable: false,
    );

    final rawId = safe[0].trim();
    final name = safe[1].trim();
    final fatherName = safe[2].trim();
    final houseNumber = safe[3].trim();
    final age = _dynamicToInt(safe[4]);
    final gender = safe[5].trim();
    final epicId = safe[6].trim();

    return Voter(
      id: rawId.isEmpty ? null : rawId,
      name: name,
      fatherName: fatherName,
      houseNumber: houseNumber,
      age: age,
      gender: gender,
      epicId: epicId,
    );
  }

  /// Optional helper for older parts of the UI that still
  /// refer to legacy property names.
  String get guardianName => fatherName;
  String get houseNo => houseNumber;

  // Back-compat convenience getters.
  String get voterName => name;
  String get epicNo => epicId;
  String get ageText => age.toString();

  static String _dynamicToString(Object? value) {
    if (value == null) return '';
    if (value is num) {
      if (value % 1 == 0) return value.toInt().toString();
      return value.toString();
    }
    return value.toString();
  }

  static int _dynamicToInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().trim()) ?? 0;
  }
}