import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/profile_read_cache.dart';
import 'app_providers.dart';

// authNotifierProvider deliberately does NOT live here — it's declared in
// features/auth/application/providers/auth_notifier_provider.dart instead.
// Declaring it in this file used to create a real core<->feature import
// cycle (this file -> auth_notifier.dart -> this file, tool-detected,
// Master Plan P3-1), since AuthNotifier itself depends on
// authStateStreamProvider/currentUserProfileProvider below.

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
