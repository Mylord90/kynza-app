import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/application/notifiers/auth_notifier.dart';
import '../../features/auth/domain/states/auth_ui_state.dart';
import '../models/user_profile.dart';
import 'app_providers.dart';

final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Fetches the current public.users row for the authenticated session.
/// Returns null when there is no active session.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final row = await client
      .from('users')
      .select()
      .eq('id', userId)
      .maybeSingle();
  if (row == null) return null;
  return UserProfile.fromSupabase(row);
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUiState>(
  AuthNotifier.new,
);
