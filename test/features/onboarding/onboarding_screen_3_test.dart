import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/application/providers/onboarding_precache_provider.dart';
import 'package:kynza/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_ken_burns_image.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_progress.dart';
import 'package:kynza/features/onboarding/presentation/widgets/sliding_get_started_button.dart';
import 'package:kynza/l10n/app_localizations.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Overrides only `disableAnimations` on the real ambient MediaQuery
      // (size/devicePixelRatio) rather than replacing it — OnboardingScreen3
      // sizes its portrait panel and cacheWidth off the real MediaQuery.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: child,
    ),
  );
}

void main() {
  group('OnboardingScreen3', () {
    // Flutter's image cache is a process-wide singleton, not scoped to a
    // test's ProviderScope — without clearing it, an earlier test's
    // pumpAndSettle() (which gives the background decode enough real time
    // to finish and populate the cache) leaves later tests seeing an
    // already-warm cache instead of the genuinely-loading state they mean
    // to assert on.
    tearDown(() {
      imageCache.clear();
      imageCache.clearLiveImages();
    });

    testWidgets(
      'shows step 3 of 3 pagination and calls onNext after the CTA animation completes',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(OnboardingScreen3(onNext: () => tapped = true)),
        );
        await tester.pump();

        final progress = tester.widget<KynzaOnboardingProgress>(
          find.byType(KynzaOnboardingProgress),
        );
        expect(progress.itemCount, 3);
        expect(progress.currentIndex, 2);
        expect(progress.currentProgress, 1.0);

        await tester.tap(find.byType(SlidingGetStartedButton));
        expect(tapped, isFalse);
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets('wraps the carousel in a RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(OnboardingScreen3(onNext: () {})));
      await tester.pump();

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('gates onboardingImagesReadyProvider until precache resolves', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              capturedContext = context;
              return OnboardingScreen3(onNext: () {});
            },
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(capturedContext);
      expect(container.read(onboardingImagesReadyProvider), isFalse);
    });

    testWidgets(
      'Reduce Motion renders the current slide statically, calls onNext '
      'immediately on tap, and disposes without error',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            OnboardingScreen3(onNext: () => tapped = true),
            disableAnimations: true,
          ),
        );
        await tester.pump();

        final kenBurns = tester.widgetList<KynzaKenBurnsImage>(
          find.byType(KynzaKenBurnsImage),
        );
        expect(kenBurns, isNotEmpty);
        for (final widget in kenBurns) {
          expect(widget.reduceMotion, isTrue);
        }

        await tester.tap(find.byType(SlidingGetStartedButton));
        await tester.pump();
        expect(tapped, isTrue);

        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  });
}
