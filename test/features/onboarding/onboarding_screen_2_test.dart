import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/application/providers/onboarding_precache_provider.dart';
import 'package:kynza/features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_ken_burns_image.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_next_button.dart';
import 'package:kynza/features/onboarding/presentation/widgets/kynza_onboarding_progress.dart';
import 'package:kynza/l10n/app_localizations.dart';

/// The 4 screen-2 source images (assets/onboarding/screen2/...) haven't been
/// dropped into the repo yet — see the onboarding screen-2 image handoff.
/// Rerouting just those asset keys to a real, already-shipped onboarding
/// webp/lqip pair lets these tests exercise OnboardingScreen2's actual
/// image-loading path (real decode, real precache success) today instead of
/// skipping it or drowning in "Unable to load asset" noise. Once the real
/// screen-2 images land, this bundle becomes unnecessary (every key already
/// resolves), so nothing here needs to change to stop applying.
class _RerouteMissingScreen2Assets extends AssetBundle {
  _RerouteMissingScreen2Assets(this._delegate);

  final AssetBundle _delegate;

  static const _screen2Prefix = 'assets/onboarding/screen2/';

  @override
  Future<ByteData> load(String key) {
    if (!key.startsWith(_screen2Prefix)) return _delegate.load(key);
    final standIn = key.contains('/lqip/')
        ? 'assets/onboarding/lqip/slide_1_barber_lqip.webp'
        : 'assets/onboarding/webp/slide_1_barber.webp';
    return _delegate.load(standIn);
  }
}

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return ProviderScope(
    child: DefaultAssetBundle(
      bundle: _RerouteMissingScreen2Assets(rootBundle),
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Overrides only `disableAnimations` on the real ambient MediaQuery
        // (size/devicePixelRatio) rather than replacing it — OnboardingScreen2
        // sizes its portrait panel and cacheWidth off the real MediaQuery, so
        // stubbing one in above MaterialApp (Size.zero by default) breaks it.
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
  group('OnboardingScreen2', () {
    testWidgets('shows step 2 of 3 pagination and calls onNext on tap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(OnboardingScreen2(onNext: () => tapped = true)),
      );
      await tester.pump();

      final progress = tester.widget<KynzaOnboardingProgress>(
        find.byType(KynzaOnboardingProgress),
      );
      expect(progress.itemCount, 3);
      expect(progress.currentIndex, 1);

      await tester.tap(find.byType(KynzaOnboardingNextButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('wraps the carousel in a RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(OnboardingScreen2(onNext: () {})));
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
              return OnboardingScreen2(onNext: () {});
            },
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(capturedContext);
      expect(container.read(onboardingImagesReadyProvider), isFalse);
    });

    testWidgets(
      'Reduce Motion renders the current slide statically and disposes without error',
      (tester) async {
        await tester.pumpWidget(
          _wrap(OnboardingScreen2(onNext: () {}), disableAnimations: true),
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
