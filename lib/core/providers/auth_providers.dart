import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/application/notifiers/auth_notifier.dart';
import '../../features/auth/domain/states/auth_ui_state.dart';
import '../models/user_profile.dart';
import '../services/profile_read_cache.dart';
import 'app_providers.dart';

final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Fetches the current public.users row for the authenticated session.
/// Returns null when there is no active session. Cold-start-offline fix
/// (Master Plan CP3, `BUSINESS_CONTINUITY_REPORT.md`): falls back to the
/// last-cached snapshot on any error, same convention as
/// `cmsPublishedProvider`.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  try {
    final row = await client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    final profile = UserProfile.fromSupabase(row);
    await ProfileReadCache.set(userId, profile);
    return profile;
  } catch (_) {
    return ProfileReadCache.get(userId);
  }
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUiState>(
  AuthNotifier.new,
);
