abstract class RouteNames {
  static const splash = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const callback = '/auth/callback';
  static const completeProfile = '/auth/complete-profile';
  static const acceptInvitation = '/accept-invitation';
  static const homeOwner = '/owner/dashboard';
  static const homeManager = '/manager/dashboard';
  static const homeStaff = '/staff/today';
  static const homeClient = '/client/home';

  // Phase 2 — Subphase A
  static const ownerSalonCreate = '/owner/salon/create';

  // Phase 2 — Subphase B
  static const ownerServices = '/owner/services';

  // Phase 2 — Subphase C
  static const ownerStaff = '/owner/staff';

  // Phase 2 — Subphase D
  static const ownerAvailability = '/owner/availability';

  // Phase 2 — Subphase F/G
  static const clientDiscover = '/client/discover';
  static const clientSalonDetail = '/client/salon/:id';
  static const clientBooking = '/client/booking';
  static const clientPayment = '/client/payment/:id';
  static const clientBookingConfirm = '/client/booking/confirm';

  static String clientSalonDetailPath(String id) => '/client/salon/$id';
}
