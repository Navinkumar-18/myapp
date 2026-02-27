import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a new system user
  /// Returns null on success, or error message on failure
  Future<String?> createUser({
    required String email,
    required String username,
    required String phone,
    required String password,
    required String role,
    String? managedBy,
  }) async {
    try {
      // Validate inputs
      final validationError = _validateInputs(
        email: email,
        username: username,
        phone: phone,
        password: password,
        role: role,
      );

      if (validationError != null) {
        return validationError;
      }

      // Check for duplicate phone number
      final phoneExists = await _checkPhoneExists(phone);
      if (phoneExists) {
        return 'Phone number already exists';
      }

      // Create Auth user using admin API
      final authUser = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Auto-confirm the email
        ),
      );

      // Insert user into profiles table
      await _client.from('profiles').insert({
        'id': authUser.user?.id,
        'username': username,
        'phone': phone,
        'role': role,
        'managed_by': managedBy,
        'is_active': true,
      });

      return null; // Success
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return 'Failed to create user: $error';
    }
  }

  /// Validate all input fields
  String? _validateInputs({
    required String email,
    required String username,
    required String phone,
    required String password,
    required String role,
  }) {
    if (email.isEmpty || username.isEmpty || phone.isEmpty || password.isEmpty) {
      return 'All fields are required';
    }

    if (!_isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (username.length > 20) {
      return 'Username must not exceed 20 characters';
    }

    if (!_isValidIndianPhone(phone)) {
      return 'Please enter a valid Indian phone number (10 digits, starting with 6-9)';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (role.isEmpty) {
      return 'Please select a role';
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate Indian phone number format
  /// Indian phone numbers are 10 digits, starting with 6, 7, 8, or 9
  bool _isValidIndianPhone(String phone) {
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return phoneRegex.hasMatch(cleanedPhone);
  }

  /// Check if phone number already exists in profiles table
  Future<bool> _checkPhoneExists(String phone) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      return response != null;
    } catch (error) {
      return false;
    }
  }

  /// Get all admin users for managed_by dropdown
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, username')
          .eq('role', 'admin')
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      return [];
    }
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client.from('profiles').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      return [];
    }
  }

  /// Deactivate a user
  Future<String?> deactivateUser(String userId) async {
    try {
      await _client.from('profiles').update({'is_active': false}).eq('id', userId);
      return null;
    } catch (error) {
      return 'Failed to deactivate user: $error';
    }
  }
}
