import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/user_profile.dart';

part 'auth_ui_state.freezed.dart';

@freezed
class AuthUiState with _$AuthUiState {
  const factory AuthUiState.initial() = AuthInitial;
  const factory AuthUiState.loading() = AuthLoading;
  const factory AuthUiState.authenticated(UserProfile user) = AuthAuthenticated;
  const factory AuthUiState.unauthenticated() = AuthUnauthenticated;
  const factory AuthUiState.emailNotVerified(String email, String? userId) =
      AuthEmailNotVerified;
  const factory AuthUiState.profileIncomplete(String userId) =
      AuthProfileIncomplete;
  const factory AuthUiState.error(String message) = AuthError;
}
