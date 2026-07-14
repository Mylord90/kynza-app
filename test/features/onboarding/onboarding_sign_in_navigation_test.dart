import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kynza/core/router/route_names.dart';

/// Proves the exact onSignIn navigation contract wired in app_router.dart's
/// onboardingStep3 route — `markOnboardingDone()` then `context.push(login)`
/// (never `go`) — using a lightweight stand-in instead of the real
/// OnboardingScreen3. The real screen (carousel, Ken Burns, image precache)
/// is already covered by onboarding_screen_3_test.dart and
/// onboarding_sign_in_link_test.dart; dragging that heavy machinery into a
/// GoRouter push/pop test adds real risk (a still-mounted carousel keeps a
/// Timer.periodic alive after push(), which doesn't dispose the previous
/// page) for no extra proof — what's being verified here is purely the
/// navigation mechanics, which any screen can stand in for.
///
/// `Navigator.canPop()` is the proof that a page was pushed (stack depth
/// >1) rather than checking whether the previous page's widget is still
/// findable in the tree — go_router doesn't keep an inactive page's widget
/// built while it's not on top, only its route entry, so presence-checking
/// the old widget mid-stack isn't a reliable signal here.
void main() {
  testWidgets(
    'onSignIn marks onboarding done before pushing Login (stack grows, '
    'not replaced), and popping Login returns to the previous screen',
    (tester) async {
      var markOnboardingDoneCalled = false;
      late BuildContext screen3Context;

      final router = GoRouter(
        initialLocation: '/stand-in-screen3',
        routes: [
          GoRoute(
            path: '/stand-in-screen3',
            builder: (context, state) {
              screen3Context = context;
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      // Exactly app_router.dart's onboardingStep3 onSignIn body.
                      markOnboardingDoneCalled = true;
                      context.push(RouteNames.login);
                    },
                    child: const Text('SIGN_IN_LINK_STAND_IN'),
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: RouteNames.login,
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('LOGIN_STAND_IN'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('SIGN_IN_LINK_STAND_IN'), findsOneWidget);
      expect(Navigator.of(screen3Context).canPop(), isFalse);

      await tester.tap(find.text('SIGN_IN_LINK_STAND_IN'));
      await tester.pumpAndSettle();

      expect(markOnboardingDoneCalled, isTrue);
      expect(find.text('LOGIN_STAND_IN'), findsOneWidget);
      // A page was pushed (stack depth > 1), not replaced — go()/replace
      // would leave nothing to pop back to.
      expect(Navigator.of(screen3Context).canPop(), isTrue);

      await tester.tap(find.text('LOGIN_STAND_IN'));
      await tester.pumpAndSettle();

      // Popping Login returns to screen 3's stand-in (never screen 1).
      expect(find.text('LOGIN_STAND_IN'), findsNothing);
      expect(find.text('SIGN_IN_LINK_STAND_IN'), findsOneWidget);
    },
  );
}
