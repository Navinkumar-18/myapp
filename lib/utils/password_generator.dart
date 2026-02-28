import 'dart:math';

class PasswordGenerator {
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _special = '!@#\$%^&*_+-=';

  /// Generate a random password of specified length (default 8)
  /// Includes uppercase, lowercase, numbers, and special characters
  static String generatePassword({int length = 8}) {
    if (length < 4) {
      length = 8; // Enforce minimum length
    }

    final random = Random.secure();
    final allChars = _uppercase + _lowercase + _numbers + _special;
    final password = <String>[];

    // Ensure at least one character from each category
    password.add(_uppercase[random.nextInt(_uppercase.length)]);
    password.add(_lowercase[random.nextInt(_lowercase.length)]);
    password.add(_numbers[random.nextInt(_numbers.length)]);
    password.add(_special[random.nextInt(_special.length)]);

    // Fill remaining length with random characters
    for (int i = password.length; i < length; i++) {
      password.add(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle the password to mix categories
    password.shuffle(random);
    return password.join();
  }
}
