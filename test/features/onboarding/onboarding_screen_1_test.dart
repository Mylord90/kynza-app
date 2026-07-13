import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_ken_burns_image.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_next_button.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_progress.dart';
import 'package:kynza/l10n/app_localizations.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Overrides only `disableAnimations` on the real ambient MediaQuery
      // rather than replacing it — OnboardingScreen1 sizes its portrait
      // panel and cacheWidth off the real MediaQuery.
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
  group('OnboardingScreen1', () {
    testWidgets(
      'shows step 1 of 3 pagination (flow position, not image rhythm) and calls onNext on tap',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(OnboardingScreen1(onNext: () => tapped = true)),
        );
        await tester.pump();

        final progress = tester.widget<KynzaOnboardingProgress>(
          find.byType(KynzaOnboardingProgress),
        );
        expect(progress.itemCount, 3);
        expect(progress.currentIndex, 0);
        expect(progress.currentProgress, 1.0);

        await tester.tap(find.byType(KynzaOnboardingNextButton));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    testWidgets('wraps the carousel in a RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(OnboardingScreen1(onNext: () {})));
      await tester.pump();

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets(
      'Reduce Motion renders the current slide statically and disposes without error',
      (tester) async {
        await tester.pumpWidget(
          _wrap(OnboardingScreen1(onNext: () {}), disableAnimations: true),
        );
        await tester.pump();

        final kenBurns = tester.widgetList<KynzaKenBurnsImage>(
          find.byType(KynzaKenBurnsImage),
        );
        expect(kenBurns, isNotEmpty);
        for (final widget in kenBurns) {
          expect(widget.reduceMotion, isTrue);
        }

        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  });
}
