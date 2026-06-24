import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/home_client/presentation/screens/home_client_screen.dart';
import '../../features/home_manager/presentation/screens/home_manager_screen.dart';
import '../../features/home_owner/presentation/screens/home_owner_screen.dart';
import '../../features/home_staff/presentation/screens/home_staff_screen.dart';
import '../../features/availability/presentation/screens/availability_management_screen.dart';
import '../../features/booking/application/providers/booking_flow_provider.dart';
import '../../features/booking/application/providers/booking_providers.dart';
import '../../features/booking/presentation/screens/salon_detail_screen.dart';
import '../../features/booking/presentation/screens/salon_discovery_screen.dart';
import '../../features/booking/presentation/screens/service_selection_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/salon/application/providers/salon_providers.dart';
import '../../shared/widgets/kynza_widgets.dart';
import '../../features/salon/presentation/screens/salon_creation_wizard_screen.dart';
import '../../features/services/presentation/screens/services_list_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/staff/presentation/screens/accept_invitation_screen.dart';
import '../../features/staff/presentation/screens/staff_list_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../enums/user_role.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_redirect.dart';
import '../widgets/kynza_full_page_lock.dart';
import 'auth_callback_screen.dart';
import 'route_names.dart';

/// Exposed so non-widget code (e.g. FCM foreground/tap handlers) can reach
/// the current [BuildContext] without threading it through every callback.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    // The com.kynza.app://accept-invitation deep link parses with
    // 'accept-invitation' as the URI *host* (custom schemes have no
    // path segment before a query string), not as a go_router path —
    // rewrite it to the real route before any path-based matching below.
    if (state.uri.host == 'accept-invitation' &&
        state.matchedLocation != RouteNames.acceptInvitation) {
      final token = state.uri.queryParameters['token'];
      return token != null
          ? '${RouteNames.acceptInvitation}?token=$token'
          : RouteNames.acceptInvitation;
    }

    final path = state.matchedLocation;
    final isAuthRoute = path.startsWith('/auth');
    final isSplash = path == RouteNames.splash;
    final isAcceptInvitation = path == RouteNames.acceptInvitation;
    final isGuestRoute =
        path == RouteNames.login ||
        path == RouteNames.register ||
        path == RouteNames.forgotPassword;

    final authValue = ref.read(authNotifierProvider);
    if (authValue.isLoading) return null;

    final authState = authValue.valueOrNull;
    if (authState == null) return null;

    return authState.when(
      initial: () => null,
      loading: () => null,
      error: (_) => null,
      // The splash screen owns its own minimum-display-time transition
      // (see SplashScreen) — the generic guard never touches '/'.
      unauthenticated: () {
        if (isAuthRoute || isSplash || isAcceptInvitation) return null;
        return RouteNames.login;
      },
      authenticated: (user) {
        if (isGuestRoute) return redirectAfterAuth(user);
        return null;
      },
      emailNotVerified: (email, userId) {
        if (path == RouteNames.verifyEmail || path == RouteNames.callback) {
          return null;
        }
        return RouteNames.verifyEmail;
      },
      profileIncomplete: (userId) {
        if (path == RouteNames.completeProfile || path == RouteNames.callback) {
          return null;
        }
        return RouteNames.completeProfile;
      },
    );
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: redirect,
    routes: [
      _fadeRoute(RouteNames.splash, (context, state) => const SplashScreen()),
      _fadeRoute(RouteNames.login, (context, state) => const LoginScreen()),
      _fadeRoute(
        RouteNames.register,
        (context, state) => const RegisterScreen(),
      ),
      _fadeRoute(
        RouteNames.forgotPassword,
        (context, state) => const ForgotPasswordScreen(),
      ),
      _fadeRoute(
        RouteNames.resetPassword,
        (context, state) => const ResetPasswordScreen(),
      ),
      _fadeRoute(
        RouteNames.verifyEmail,
        (context, state) => const VerifyEmailScreen(),
      ),
      _fadeRoute(
        RouteNames.callback,
        (context, state) => const AuthCallbackScreen(),
      ),
      _fadeRoute(
        RouteNames.acceptInvitation,
        (context, state) =>
            AcceptInvitationScreen(token: state.uri.queryParameters['token']),
      ),
      _fadeRoute(
        RouteNames.completeProfile,
        (context, state) => const CompleteProfileScreen(),
      ),
      _fadeRoute(
        RouteNames.homeOwner,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: HomeOwnerScreen()),
      ),
      _fadeRoute(
        RouteNames.homeManager,
        (context, state) => const _RoleGuard(
          role: UserRole.manager,
          child: HomeManagerScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.homeStaff,
        (context, state) =>
            const _RoleGuard(role: UserRole.staff, child: HomeStaffScreen()),
      ),
      _fadeRoute(
        RouteNames.homeClient,
        (context, state) =>
            const _RoleGuard(role: UserRole.client, child: HomeClientScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerSalonCreate,
        (context, state) => const _RoleGuard(
          role: UserRole.owner,
          child: _OwnerOnboardingGuard(child: SalonCreationWizardScreen()),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerServices,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: ServicesListScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.ownerStaff,
        (context, state) =>
            const _RoleGuard(role: UserRole.owner, child: StaffListScreen()),
      ),
      _fadeRoute(
        RouteNames.ownerAvailability,
        (context, state) => const _RoleGuard.anyOf(
          roles: {UserRole.owner, UserRole.manager},
          child: AvailabilityManagementScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientDiscover,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: SalonDiscoveryScreen(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientSalonDetail,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: SalonDetailScreen(salonId: state.pathParameters['id']!),
        ),
      ),
      _fadeRoute(
        RouteNames.clientBooking,
        (context, state) => const _RoleGuard(
          role: UserRole.client,
          child: _BookingEntryGuard(),
        ),
      ),
      _fadeRoute(
        RouteNames.clientPayment,
        (context, state) => _RoleGuard(
          role: UserRole.client,
          child: _PaymentDeepLinkLoader(bookingId: state.pathParameters['id']!),
        ),
      ),
    ],
  );
});

GoRoute _fadeRoute(
  String path,
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: builder(context, state),
      transitionDuration: AppDurations.standard,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Bridges Riverpod's authNotifierProvider to GoRouter's refreshListenable
/// so navigation re-evaluates whenever the auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    _subscription = ref.listen(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<Object?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class _RoleGuard extends ConsumerWidget {
  const _RoleGuard({required UserRole role, required this.child})
    : roles = const {},
      _singleRole = role;

  const _RoleGuard.anyOf({required this.roles, required this.child})
    : _singleRole = null;

  final UserRole? _singleRole;
  final Set<UserRole> roles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = _singleRole != null ? {_singleRole} : roles;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final currentRole = authState?.whenOrNull(
      authenticated: (user) => user.role,
    );
    if (currentRole != null && !allowed.contains(currentRole)) {
      return KynzaFullPageLock(requiredRole: allowed.first);
    }
    return child;
  }
}

/// Entry point for `/client/booking` deep links — resumes the in-progress
/// tunnel if a salon was already selected (e.g. Fast-Pass), otherwise
/// sends the client back to discovery rather than a dead end (R04).
class _BookingEntryGuard extends ConsumerWidget {
  const _BookingEntryGuard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    return flowState.selectedSalon == null
        ? const SalonDiscoveryScreen()
        : const ServiceSelectionScreen();
  }
}

/// `/client/payment/:id` deep link — fetches the booking by id before
/// handing off to [PaymentScreen], which needs the full model, not just
/// the id (e.g. resuming a payment from a push notification).
class _PaymentDeepLinkLoader extends ConsumerWidget {
  const _PaymentDeepLinkLoader({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    return bookingAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: KynzaSpinner()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.homeClient),
            child: const Text('Réservation introuvable — retour à l\'accueil'),
          ),
        ),
      ),
      data: (booking) => booking == null
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: TextButton(
                  onPressed: () => context.go(RouteNames.homeClient),
                  child: const Text(
                    'Réservation introuvable — retour à l\'accueil',
                  ),
                ),
              ),
            )
          : PaymentScreen(booking: booking),
    );
  }
}

/// The salon creation wizard must never be re-enterable once a salon
/// already exists — checked here against the live `ownerSalonProvider`
/// (not the auth cache, which is not guaranteed to reflect a salon
/// created moments ago) so this never silently redirects mid-flow.
class _OwnerOnboardingGuard extends ConsumerWidget {
  const _OwnerOnboardingGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;
    if (salon != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Vous avez déjà un salon',
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  salon.name,
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go(RouteNames.homeOwner),
                  child: const Text('Aller au tableau de bord →'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
