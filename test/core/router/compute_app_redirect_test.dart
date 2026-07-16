import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kynza/core/enums/user_role.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/core/router/app_router.dart';
import 'package:kynza/core/router/deep_link_handler.dart';
import 'package:kynza/core/router/route_names.dart';
import 'package:kynza/core/services/session_service.dart';
import 'package:kynza/features/auth/application/notifiers/auth_notifier.dart';
import 'package:kynza/features/auth/application/providers/auth_notifier_provider.dart';
import 'package:kynza/features/auth/domain/states/auth_ui_state.dart';
import 'package:kynza/features/evolution/maintenance/application/providers/maintenance_providers.dart';
import 'package:kynza/features/evolution/version_manager/application/providers/version_providers.dart';

/// Same stand-in as splash_screen_test.dart — replaces the real
/// Supabase-backed build() with a fixed value.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthUiState _state;

  @override
  Future<AuthUiState> build() async => _state;
}

/// In-memory stand-in for SessionService — adds pending invitation/referral
/// token control (the D3 priority check, see Ajout 2) on top of the
/// existing splash_screen_test.dart onboarding-flag stand-in pattern. Never
/// touches real Hive.
class _FakeSessionService extends SessionService {
  bool _onboardingDone = false;
  String? _pendingInvitationToken;
  String? _pendingReferralToken;

  @override
  bool isOnboardingDone() => _onboardingDone;

  @override
  Future<void> markOnboardingDone() async => _onboardingDone = true;

  @override
  String? getPendingInvitationToken() => _pendingInvitationToken;

  @override
  Future<void> savePendingInvitationToken(String token) async =>
      _pendingInvitationToken = token;

  @override
  Future<void> clearPendingInvitationToken() async =>
      _pendingInvitationToken = null;

  @override
  String? getPendingReferralToken() => _pendingReferralToken;

  @override
  Future<void> savePendingReferralToken(String token) async =>
      _pendingReferralToken = token;

  @override
  Future<void> clearPendingReferralToken() async =>
      _pendingReferralToken = null;
}

UserProfile _profile({required UserRole role}) => UserProfile(
  id: 'test-user',
  role: role,
  emailVerified: true,
  profileCompleted: true,
);

/// A Ref is normally only available inside a provider's own build callback
/// — this reads a throwaway provider whose value is literally its own ref,
/// to get a usable Ref handle out of a ProviderContainer for a direct call
/// to computeAppRedirect.
final _refProvider = Provider<Ref>((ref) => ref);

/// Tiny throwaway router — purely for `.configuration` (route-existence
/// checks) and to satisfy computeAppRedirect's `router` parameter. Never
/// pumped as a widget: go_router's real `redirect` needs a BuildContext
/// sourced from a mounted Router, which is exactly why computeAppRedirect
/// was extracted out of that closure — nothing here needs one either.
///
/// Disposed via addTearDown: GoRouter.dispose() releases its
/// routeInformationProvider/routerDelegate, and this helper is called fresh
/// in nearly every test — leaving that many undisposed routers accumulate
/// across a full suite run in a way a handful of isolated tests never
/// surfaces.
GoRouter _testRouter() {
  final router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      for (final path in [
        RouteNames.splash,
        RouteNames.login,
        RouteNames.onboarding,
        RouteNames.verifyEmail,
        RouteNames.completeProfile,
        RouteNames.homeClient,
        RouteNames.notifications,
      ])
        GoRoute(path: path, builder: (context, state) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

GoRouterState _stateFor(GoRouter router, String path) => GoRouterState(
  router.configuration,
  uri: Uri.parse(path),
  matchedLocation: path,
  fullPath: path,
  pathParameters: const {},
  pageKey: const ValueKey('test'),
);

/// Async because authNotifierProvider is an AsyncNotifierProvider — even a
/// stand-in build() that returns its fixed value synchronously still
/// resolves on a microtask, not the read() call itself. Every real caller
/// of computeAppRedirect (SplashScreen via ref.listen, redirect() via
/// refreshListenable) only ever runs after that resolution has already
/// happened; awaiting `.future` here reproduces that same precondition
/// instead of racing it.
Future<ProviderContainer> _containerFor({
  required AuthUiState authState,
  required SessionService sessionService,
}) async {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(authState)),
      sessionServiceProvider.overrideWithValue(sessionService),
      appVersionCheckProvider.overrideWith((ref) async => null),
      maintenanceStatusProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authNotifierProvider.future);
  return container;
}

void main() {
  group('computeAppRedirect — D3 cold-start deep link replay', () {
    test(
      'cold start with a valid session and a pending push intent reaches '
      'the target',
      () async {
        final router = _testRouter();
        final container = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: _FakeSessionService(),
        );
        DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.splash),
          router: router,
        );

        expect(redirect, RouteNames.notifications);
      },
    );

    test(
      'cold start without a session leaves the push intent armed, '
      'unconsumed',
      () async {
        final router = _testRouter();
        final container = await _containerFor(
          authState: const AuthUiState.unauthenticated(),
          sessionService: _FakeSessionService(),
        );
        DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.homeClient),
          router: router,
        );

        expect(redirect, RouteNames.login);
        // Still armed — this consume-and-check IS the proof; the
        // unauthenticated branch never touches DeepLinkHandler.
        expect(
          DeepLinkHandler.consumePendingIntent(router.configuration),
          RouteNames.notifications,
        );
      },
    );

    test(
      'replay after login: the same in-memory intent is honored once the '
      'user authenticates',
      () async {
        final router = _testRouter();
        final sessionService = _FakeSessionService();
        DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

        // First evaluation: cold start without a session.
        final unauthContainer = await _containerFor(
          authState: const AuthUiState.unauthenticated(),
          sessionService: sessionService,
        );
        final unauthRedirect = computeAppRedirect(
          ref: unauthContainer.read(_refProvider),
          state: _stateFor(router, RouteNames.login),
          router: router,
        );
        expect(unauthRedirect, isNull); // already on /auth/login

        // Second evaluation: after a successful sign-in.
        final authContainer = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: sessionService,
        );
        final authRedirect = computeAppRedirect(
          ref: authContainer.read(_refProvider),
          state: _stateFor(router, RouteNames.homeClient),
          router: router,
        );

        expect(authRedirect, RouteNames.notifications);
      },
    );

    test('rejeu unique — the same intent is never replayed twice', () async {
      final router = _testRouter();
      final container = await _containerFor(
        authState: AuthUiState.authenticated(_profile(role: UserRole.client)),
        sessionService: _FakeSessionService(),
      );
      DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

      final first = computeAppRedirect(
        ref: container.read(_refProvider),
        state: _stateFor(router, RouteNames.homeClient),
        router: router,
      );
      final second = computeAppRedirect(
        ref: container.read(_refProvider),
        state: _stateFor(router, RouteNames.notifications),
        router: router,
      );

      expect(first, RouteNames.notifications);
      expect(second, isNull);
    });

    test(
      'an unknown deep link (the real send-notification "/booking/:id" '
      'payload) is discarded silently — no crash, no replay',
      () async {
        final router = _testRouter();
        final container = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: _FakeSessionService(),
        );
        DeepLinkHandler.capturePendingIntent('/booking/abc123');

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.homeClient),
          router: router,
        );

        expect(redirect, isNull);
      },
    );

    group('priority: a pending invitation/referral token always wins', () {
      test('invitation token armed -> push intent stays unconsumed', () async {
        final router = _testRouter();
        final sessionService = _FakeSessionService()
          ..savePendingInvitationToken('tok-123');
        final container = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: sessionService,
        );
        DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.homeClient),
          router: router,
        );

        expect(redirect, isNull);
        expect(
          DeepLinkHandler.consumePendingIntent(router.configuration),
          RouteNames.notifications,
        );
      });

      test('referral token armed -> push intent stays unconsumed', () async {
        final router = _testRouter();
        final sessionService = _FakeSessionService()
          ..savePendingReferralToken('ref-456');
        final container = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: sessionService,
        );
        DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.homeClient),
          router: router,
        );

        expect(redirect, isNull);
        expect(
          DeepLinkHandler.consumePendingIntent(router.configuration),
          RouteNames.notifications,
        );
      });

      test(
        'once the invitation token clears, a later evaluation replays the '
        'push intent',
        () async {
          final router = _testRouter();
          final sessionService = _FakeSessionService()
            ..savePendingInvitationToken('tok-123');
          DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

          final blockedContainer = await _containerFor(
            authState: AuthUiState.authenticated(
              _profile(role: UserRole.client),
            ),
            sessionService: sessionService,
          );
          final blocked = computeAppRedirect(
            ref: blockedContainer.read(_refProvider),
            state: _stateFor(router, RouteNames.homeClient),
            router: router,
          );
          expect(blocked, isNull);

          sessionService.clearPendingInvitationToken();

          final replayedContainer = await _containerFor(
            authState: AuthUiState.authenticated(
              _profile(role: UserRole.client),
            ),
            sessionService: sessionService,
          );
          final replayed = computeAppRedirect(
            ref: replayedContainer.read(_refProvider),
            state: _stateFor(router, RouteNames.homeClient),
            router: router,
          );
          expect(replayed, RouteNames.notifications);
        },
      );
    });
  });

  group('computeAppRedirect — unchanged branches (extraction regression)', () {
    test('unauthenticated on a non-auth route -> login', () async {
      final router = _testRouter();
      final container = await _containerFor(
        authState: const AuthUiState.unauthenticated(),
        sessionService: _FakeSessionService(),
      );

      final redirect = computeAppRedirect(
        ref: container.read(_refProvider),
        state: _stateFor(router, RouteNames.homeClient),
        router: router,
      );

      expect(redirect, RouteNames.login);
    });

    test(
      'unauthenticated, already on an allowed unauthenticated route -> null',
      () async {
        final router = _testRouter();
        final container = await _containerFor(
          authState: const AuthUiState.unauthenticated(),
          sessionService: _FakeSessionService(),
        );

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.login),
          router: router,
        );

        expect(redirect, isNull);
      },
    );

    test(
      'authenticated on a guest route -> redirectAfterAuth destination',
      () async {
        final router = _testRouter();
        final container = await _containerFor(
          authState: AuthUiState.authenticated(
            _profile(role: UserRole.client),
          ),
          sessionService: _FakeSessionService(),
        );

        final redirect = computeAppRedirect(
          ref: container.read(_refProvider),
          state: _stateFor(router, RouteNames.login),
          router: router,
        );

        expect(redirect, RouteNames.homeClient);
      },
    );

    test('emailNotVerified -> verifyEmail', () async {
      final router = _testRouter();
      final container = await _containerFor(
        authState: const AuthUiState.emailNotVerified(
          'a@b.com',
          'test-user',
        ),
        sessionService: _FakeSessionService(),
      );

      final redirect = computeAppRedirect(
        ref: container.read(_refProvider),
        state: _stateFor(router, RouteNames.homeClient),
        router: router,
      );

      expect(redirect, RouteNames.verifyEmail);
    });

    test('profileIncomplete -> completeProfile', () async {
      final router = _testRouter();
      final container = await _containerFor(
        authState: const AuthUiState.profileIncomplete('test-user'),
        sessionService: _FakeSessionService(),
      );

      final redirect = computeAppRedirect(
        ref: container.read(_refProvider),
        state: _stateFor(router, RouteNames.homeClient),
        router: router,
      );

      expect(redirect, RouteNames.completeProfile);
    });
  });
}
