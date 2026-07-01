import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/loader/kynza_loader.dart';
import 'package:kynza/shared/widgets/loader/models/loader_size.dart';
import 'package:kynza/shared/widgets/loader/models/loader_variant.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_button.dart';

/// Golden references live under `test/golden/goldens/`. Regenerate with
/// `flutter test --update-goldens test/golden/kynza_loader_golden_test.dart`
/// — as with any golden test, a human must eyeball the generated PNGs once
/// before trusting them as the baseline; this suite only guarantees the
/// render is byte-stable across runs, not that it looks right.
Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(child: child),
    ),
  );
}

void main() {
  testWidgets(
    'KynzaLoader orbit variant - small size - frame at progress 0.0',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const KynzaLoader(size: KynzaLoaderSize.small)),
      );
      await tester.pump();

      await expectLater(
        find.byType(KynzaLoader),
        matchesGoldenFile('goldens/kynza_loader_orbit_small_p0.png'),
      );
    },
  );

  testWidgets(
    'KynzaLoader orbit variant - medium size - frame at progress 0.5',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const KynzaLoader(size: KynzaLoaderSize.medium)),
      );
      await tester.pump(const Duration(milliseconds: 700));

      await expectLater(
        find.byType(KynzaLoader),
        matchesGoldenFile('goldens/kynza_loader_orbit_medium_p50.png'),
      );
    },
  );

  testWidgets(
    'KynzaLoader orbit variant - large size - frame at progress 0.25',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const KynzaLoader(size: KynzaLoaderSize.large)),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await expectLater(
        find.byType(KynzaLoader),
        matchesGoldenFile('goldens/kynza_loader_orbit_large_p25.png'),
      );
    },
  );

  testWidgets('KynzaLoader pulse variant - frame at progress 0.0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const KynzaLoader(
          size: KynzaLoaderSize.medium,
          variant: KynzaLoaderVariant.pulse,
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(KynzaLoader),
      matchesGoldenFile('goldens/kynza_loader_pulse_p0.png'),
    );
  });

  testWidgets('KynzaLoader pulse variant - frame at progress 0.5', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const KynzaLoader(
          size: KynzaLoaderSize.medium,
          variant: KynzaLoaderVariant.pulse,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    await expectLater(
      find.byType(KynzaLoader),
      matchesGoldenFile('goldens/kynza_loader_pulse_p50.png'),
    );
  });

  testWidgets('KynzaLoaderButton golden - small size', (tester) async {
    await tester.pumpWidget(_wrap(const KynzaLoaderButton()));
    await tester.pump();

    await expectLater(
      find.byType(KynzaLoaderButton),
      matchesGoldenFile('goldens/kynza_loader_button_small.png'),
    );
  });
}
