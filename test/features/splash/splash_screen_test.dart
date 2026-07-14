import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kynza/core/enums/user_role.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/core/router/route_names.dart';
import 'package:kynza/core/services/session_service.dart';
import 'package:kynza/features/auth/application/notifiers/auth_notifier.dart';
import 'package:kynza/features/auth/application/providers/auth_notifier_provider.dart';
import 'package:kynza/features/auth/domain/states/auth_ui_state.dart';
import 'package:kynza/features/splash/presentation/screens/splash_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';

/// Replaces the real Supabase-backed build() with a fixed value so these
/// tests never touch the network — SplashScreen only reads whatever
/// authNotifierProvider currently holds, it doesn't care how that value
/// was produced.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthUiState _state;

  @override
  Future<AuthUiState> build() async => _state;
}

/// In-memory stand-in for the one flag SplashScreen actually reads
/// (`isOnboardingDone`) — avoids real Hive/disk I/O for this test, which
/// only needs to prove the flag's effect on navigation, not Hive's own
/// persistence (already covered by SessionService's existing usage
/// elsewhere and by `salon_location_cache_test.dart`-style Hive tests).
class _FakeSessionService extends SessionService {
  bool _onboardingDone = false;

  @override
  bool isOnboardingDone() => _onboardingDone;

  @override
  Future<void> markOnboardingDone() async => _onboardingDone = true;
}

UserProfile _profile({required UserRole role}) => UserProfile(
  id: 'test-user',
  role: role,
  emailVerified: true,
  profileCompleted: true,
);

/// Standalone router with stand-in destination screens — proves exactly
/// what SplashScreen._maybeNavigate() decides (splash_screen.dart:82-109),
/// without needing the full, auth-gated production router.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const Text('ONBOARDING_STAND_IN'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const Text('LOGIN_STAND_IN'),
      ),
      GoRoute(
        path: RouteNames.homeClient,
        builder: (context, state) => const Text('HOME_CLIENT_STAND_IN'),
      ),
    ],
  );
}

Future<void> _pumpPastMinDisplay(WidgetTester tester) async {
  // SplashScreen's shimmer AnimationController repeats forever, so
  // pumpAndSettle() would never settle while it's still mounted — advance
  // real/virtual time explicitly instead (matches the pattern already
  // established for OnboardingCrossfadeCarousel-based screens).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1600)); // past _minDisplay
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // let nav settle
}

Widget _wrap(AuthUiState authState, SessionService sessionService) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(authState)),
      sessionServiceProvider.overrideWithValue(sessionService),
    ],
    child: MaterialApp.router(
      routerConfig: _buildTestRouter(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('SplashScreen — 3-branch launch decision', () {
    testWidgets(
      'a brand-new unauthenticated user (never seen onboarding) goes to Onboarding',
      (tester) async {
        final sessionService = _FakeSessionService();
        await tester.pumpWidget(
          _wrap(const AuthUiState.unauthenticated(), sessionService),
        );
        addTearDown(() => tester.pumpWidget(const SizedBox()));
        await _pumpPastMinDisplay(tester);

        expect(find.text('ONBOARDING_STAND_IN'), findsOneWidget);
      },
    );

    testWidgets(
      'an unauthenticated user who already finished onboarding goes to Login',
      (tester) async {
        final sessionService = _FakeSessionService()..markOnboardingDone();
        await tester.pumpWidget(
          _wrap(const AuthUiState.unauthenticated(), sessionService),
        );
        addTearDown(() => tester.pumpWidget(const SizedBox()));
        await _pumpPastMinDisplay(tester);

        expect(find.text('LOGIN_STAND_IN'), findsOneWidget);
      },
    );

    testWidgets(
      'an authenticated user goes straight to Home — never onboarding, never login',
      (tester) async {
        final profile = _profile(role: UserRole.client);
        final sessionService = _FakeSessionService();
        await tester.pumpWidget(
          _wrap(AuthUiState.authenticated(profile), sessionService),
        );
        addTearDown(() => tester.pumpWidget(const SizedBox()));
        await _pumpPastMinDisplay(tester);

        expect(find.text('HOME_CLIENT_STAND_IN'), findsOneWidget);
        expect(find.text('ONBOARDING_STAND_IN'), findsNothing);
        expect(find.text('LOGIN_STAND_IN'), findsNothing);
      },
    );
  });
}
