import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Check if a valid session exists
  bool hasActiveSession() {
    final session = _client.auth.currentSession;
    return session != null && !session.isExpired;
  }

  /// Get current user's username from profiles table
  Future<String?> getCurrentUsername() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return response['username'] as String?;
      }
      return null;
    } catch (error) {
      debugPrint('Error fetching username: $error');
      return null;
    }
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Logout current session
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      debugPrint('Error during logout: $error');
    }
  }
}
