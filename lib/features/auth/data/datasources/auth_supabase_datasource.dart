import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/auth_errors.dart';

/// Talks to Supabase Auth exclusively. Never calls Leapa or any other
/// third-party API directly (R16) — payments are a separate concern.
class AuthSupabaseDatasource {
  static const String _redirectTo = '${Env.supabaseUrl}/auth/callback';

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      return await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: _redirectTo,
      );
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      return await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectTo,
      );
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  /// Stub — architecture ready, ships in V2.
  Future<void> signInWithFacebook() =>
      throw UnimplementedError('Facebook sign-in arrives in V2.');

  /// Stub — architecture ready, ships in V2.
  Future<void> signInWithApple() =>
      throw UnimplementedError('Apple sign-in arrives in V2.');

  Future<void> sendPasswordReset(String email) async {
    try {
      await SupabaseService.auth.resetPasswordForEmail(
        email,
        redirectTo: _redirectTo,
      );
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await SupabaseService.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await SupabaseService.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.auth.signOut();
    } catch (e) {
      throw AppException(getAuthErrorMessage(e));
    }
  }

  /// Fetches the public.users row for [userId], retrying up to 3 times with
  /// a 500ms delay to absorb the on_auth_user_created trigger's latency.
  Future<UserProfile> fetchProfileWithRetry(String userId) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final row = await SupabaseService.from(
        'users',
      ).select().eq('id', userId).maybeSingle();
      if (row != null) return UserProfile.fromSupabase(row);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw const AppException(
      'Profil introuvable. Réessayez dans quelques instants.',
    );
  }
}
