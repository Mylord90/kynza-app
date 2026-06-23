import '../../../../core/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> signUpWithEmail(
    String email,
    String password,
    String fullName,
  );

  Future<UserProfile> signInWithEmail(String email, String password);

  Future<UserProfile> signInWithGoogle();

  /// Architecture ready, stub in V1.
  Future<void> signInWithFacebook();

  /// Architecture ready, stub in V1.
  Future<void> signInWithApple();

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> resendVerificationEmail(String email);

  Future<UserProfile?> getCurrentUser();

  Future<void> signOut();

  Stream<bool> get isAuthenticated;
}
