import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_supabase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthSupabaseDatasource _datasource;

  @override
  Future<UserProfile> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await _datasource.signUpWithEmail(
      email,
      password,
      fullName,
    );
    final userId = response.user?.id;
    if (userId == null) {
      throw const AppException('Inscription impossible. Réessayez.');
    }
    return _datasource.fetchProfileWithRetry(userId);
  }

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final response = await _datasource.signInWithEmail(email, password);
    final userId = response.user?.id;
    if (userId == null) {
      throw const AppException('Connexion impossible. Réessayez.');
    }
    return _datasource.fetchProfileWithRetry(userId);
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    await _datasource.signInWithGoogle();
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Connexion Google impossible. Réessayez.');
    }
    return _datasource.fetchProfileWithRetry(userId);
  }

  @override
  Future<void> signInWithFacebook() => _datasource.signInWithFacebook();

  @override
  Future<void> signInWithApple() => _datasource.signInWithApple();

  @override
  Future<void> sendPasswordReset(String email) =>
      _datasource.sendPasswordReset(email);

  @override
  Future<void> updatePassword(String newPassword) =>
      _datasource.updatePassword(newPassword);

  @override
  Future<void> resendVerificationEmail(String email) =>
      _datasource.resendVerificationEmail(email);

  @override
  Future<UserProfile?> getCurrentUser() async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return null;
    return _datasource.fetchProfileWithRetry(userId);
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Stream<bool> get isAuthenticated => SupabaseService.auth.onAuthStateChange
      .map((state) => state.session != null);
}
