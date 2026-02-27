import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sign in user with email and password
  /// Returns null on success, or error message on failure
  Future<String?> login(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password cannot be empty';
      }

      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      if (password.length < 6) {
        return 'Password must be at least 6 characters';
      }

      // Attempt sign in
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if user is authenticated
      if (response.user != null) {
        return null; // Success
      } else {
        return 'Authentication failed';
      }
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return 'An unexpected error occurred: $error';
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Sign out current user
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Demo login for testing (no Supabase required)
  /// Accepts any email/password combination for demo purposes
  Future<String?> demoLogin(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password cannot be empty';
      }

      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      if (password.length < 6) {
        return 'Password must be at least 6 characters';
      }

      // Demo login always succeeds - for testing purposes only
      return null; // Success
    } catch (error) {
      return 'An unexpected error occurred: $error';
    }
  }
}
