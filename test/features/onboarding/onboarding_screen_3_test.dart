import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/application/providers/onboarding_precache_provider.dart';
import 'package:kynza/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_ken_burns_image.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_progress.dart';
import 'package:kynza/features/onboarding/presentation/widgets/sliding_get_started_button.dart';
import 'package:kynza/l10n/app_localizations.dart';

/// Screen 3's source images (assets/onboarding/screen3/...) haven't been
/// dropped into the repo yet — see the onboarding screen-3 image handoff
/// (Section 0.3). Same rerouting trick as OnboardingScreen2's test: point
/// those asset keys at an already-shipped webp/lqip pair so these tests
/// exercise the real image-loading path today instead of skipping it.
class _RerouteMissingScreen3Assets extends AssetBundle {
  _RerouteMissingScreen3Assets(this._delegate);

  final AssetBundle _delegate;

  static const _screen3Prefix = 'assets/onboarding/screen3/';

  @override
  Future<ByteData> load(String key) {
    if (!key.startsWith(_screen3Prefix)) return _delegate.load(key);
    final standIn = key.contains('/lqip/')
        ? 'assets/onboarding/lqip/slide_1_barber_lqip.webp'
        : 'assets/onboarding/webp/slide_1_barber.webp';
    return _delegate.load(standIn);
  }
}

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return ProviderScope(
    child: DefaultAssetBundle(
      bundle: _RerouteMissingScreen3Assets(rootBundle),
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
    ),
  );
}

void main() {
  group('OnboardingScreen3', () {
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
