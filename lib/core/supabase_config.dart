import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://pqcwpxdjvsfbcbrswciw.supabase.co';
  static const String anonKey =
      'sb_publishable_ZtPrtRL76rrkMk36IsXgvg_cDL5y5LQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}