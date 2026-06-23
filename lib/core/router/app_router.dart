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
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../constants/app_durations.dart';
import '../enums/user_role.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_redirect.dart';
import '../widgets/kynza_full_page_lock.dart';
import 'auth_callback_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;
    final isAuthRoute = path.startsWith('/auth');
    final isSplash = path == RouteNames.splash;
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
        if (isAuthRoute || isSplash) return null;
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
  const _RoleGuard({required this.role, required this.child});

  final UserRole role;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final currentRole = authState?.whenOrNull(
      authenticated: (user) => user.role,
    );
    if (currentRole != null && currentRole != role) {
      return KynzaFullPageLock(requiredRole: role);
    }
    return child;
  }
}
