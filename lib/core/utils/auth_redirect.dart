import '../enums/user_role.dart';
import '../models/user_profile.dart';
import '../router/route_names.dart';
import '../services/session_service.dart';

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

/// Same as [redirectAfterAuth], except a staff invitation token stashed by
/// AcceptInvitationScreen (saved when a brand-new/logged-out staff member
/// had to detour through register/login first) takes priority — without
/// this, a fresh signup would land on the normal role-based home instead
/// of finishing the invitation it arrived from.
Future<String> resolvePostAuthRoute(
  SessionService sessionService,
  UserProfile profile,
) async {
  final pendingInvitation = sessionService.getPendingInvitationToken();
  if (pendingInvitation != null) {
    await sessionService.clearPendingInvitationToken();
    return '${RouteNames.acceptInvitation}?token=$pendingInvitation';
  }
  final pendingReferral = sessionService.getPendingReferralToken();
  if (pendingReferral != null) {
    await sessionService.clearPendingReferralToken();
    return '${RouteNames.acceptReferral}?token=$pendingReferral';
  }
  return redirectAfterAuth(profile);
}
