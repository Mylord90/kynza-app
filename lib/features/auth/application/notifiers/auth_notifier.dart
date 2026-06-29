import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/auth_errors.dart';
import '../../data/datasources/auth_supabase_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/states/auth_ui_state.dart';

class AuthNotifier extends AsyncNotifier<AuthUiState> {
  final AuthRepository _repository = AuthRepositoryImpl(
    AuthSupabaseDatasource(),
  );

  @override
  Future<AuthUiState> build() async {
    ref.listen(authStateStreamProvider, (previous, next) {
      next.whenData(_handleAuthStateChange);
    });

    if (SupabaseService.auth.currentSession == null) {
      return const AuthUiState.unauthenticated();
    }
    return _loadCurrentSessionState();
  }

  Future<AuthUiState> _loadCurrentSessionState() async {
    try {
      final profile = await _repository.getCurrentUser();
      return profile == null
          ? const AuthUiState.unauthenticated()
          : _guard(profile);
    } catch (e) {
      return AuthUiState.error(getAuthErrorMessage(e));
    }
  }

  AuthUiState _guard(UserProfile profile) {
    if (!profile.emailVerified && profile.authProvider == 'email') {
      return AuthUiState.emailNotVerified(profile.email ?? '', profile.id);
    }
    if (!profile.profileCompleted) {
      return AuthUiState.profileIncomplete(profile.id);
    }
    CrashReportingService.setUser(profile.id, profile.role.name);
    return AuthUiState.authenticated(profile);
  }

  /// Re-derives state from the current session/profile row. Callers that
  /// mutate `public.users` directly (e.g. CompleteProfileScreen) must call
  /// this before navigating — otherwise the router's redirect guard keeps
  /// reading the stale cached state (refreshSession() only fires a
  /// tokenRefreshed auth event, which _handleAuthStateChange ignores) and
  /// immediately bounces the navigation back.
  Future<void> refreshProfile() async {
    state = AsyncData(await _loadCurrentSessionState());
  }

  void _handleAuthStateChange(AuthState authState) {
    if (authState.event == AuthChangeEvent.signedOut) {
      state = const AsyncData(AuthUiState.unauthenticated());
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.signUpWithEmail(
        email,
        password,
        fullName,
      );
      await ref.read(sessionServiceProvider).persistSession();
      ref.invalidate(currentUserProfileProvider);
      state = AsyncData(_guard(profile));
    } catch (e) {
      state = AsyncData(AuthUiState.error(getAuthErrorMessage(e)));
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.signInWithEmail(email, password);
      await ref.read(sessionServiceProvider).persistSession();
      // Without this, screens reading currentUserProfileProvider (e.g.
      // ownerSalonProvider) keep serving whichever account was cached
      // before this sign-in — a real bug hit when switching accounts
      // (sign out then back in as someone else) without a full app
      // restart.
      ref.invalidate(currentUserProfileProvider);
      state = AsyncData(_guard(profile));
    } catch (e) {
      state = AsyncData(AuthUiState.error(getAuthErrorMessage(e)));
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.signInWithGoogle();
      await ref.read(sessionServiceProvider).persistSession();
      ref.invalidate(currentUserProfileProvider);
      state = AsyncData(_guard(profile));
    } catch (e) {
      state = AsyncData(AuthUiState.error(getAuthErrorMessage(e)));
    }
  }

  /// SECURITY: never reveals whether [email] is registered — caller always
  /// shows a generic success state regardless of the outcome here.
  Future<void> forgotPassword(String email) async {
    try {
      await _repository.sendPasswordReset(email);
    } catch (_) {
      // Intentionally swallowed — see security note above.
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repository.updatePassword(newPassword);
      final profile = await _repository.getCurrentUser();
      state = AsyncData(
        profile == null ? const AuthUiState.unauthenticated() : _guard(profile),
      );
    } catch (e) {
      state = AsyncData(AuthUiState.error(getAuthErrorMessage(e)));
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _repository.resendVerificationEmail(email);
    } catch (e) {
      state = AsyncData(AuthUiState.error(getAuthErrorMessage(e)));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    await ref.read(sessionServiceProvider).clearSession();
    ref.invalidate(currentUserProfileProvider);
    state = const AsyncData(AuthUiState.unauthenticated());
  }
}
