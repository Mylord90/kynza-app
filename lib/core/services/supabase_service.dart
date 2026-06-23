import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static RealtimeClient get realtime => client.realtime;
  static SupabaseQueryBuilder from(String table) => client.from(table);
}
