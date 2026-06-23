import '../enums/user_role.dart';
import '../models/user_profile.dart';
import '../router/route_names.dart';

String redirectAfterAuth(UserProfile profile) {
  if (!profile.emailVerified && profile.authProvider == 'email') {
    return RouteNames.verifyEmail;
  }
  if (!profile.profileCompleted) return RouteNames.completeProfile;
  return switch (profile.role) {
    UserRole.owner => RouteNames.homeOwner,
    UserRole.manager => RouteNames.homeManager,
    UserRole.staff => RouteNames.homeStaff,
    UserRole.client => RouteNames.homeClient,
  };
}
