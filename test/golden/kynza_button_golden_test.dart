import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/kynza_button.dart';

/// Golden references live under `test/golden/goldens/`. Regenerate with
/// `flutter test --update-goldens test/golden/kynza_button_golden_test.dart`
/// — a human must eyeball new PNGs once before trusting them as the
/// baseline (Phase 9, Enterprise Hardening pass).
Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

void main() {
  for (final variant in KynzaButtonVariant.values) {
    testWidgets('KynzaButton ${variant.name} variant - enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          KynzaButton(label: 'Continuer', variant: variant, onPressed: () {}),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(KynzaButton),
        matchesGoldenFile('goldens/kynza_button_${variant.name}_enabled.png'),
      );
    });
  }

  testWidgets('KynzaButton primary variant - disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(const KynzaButton(label: 'Continuer', onPressed: null)),
    );
    await tester.pump();

    await expectLater(
      find.byType(KynzaButton),
      matchesGoldenFile('goldens/kynza_button_primary_disabled.png'),
    );
  });

  testWidgets('KynzaButton primary variant - loading', (tester) async {
    await tester.pumpWidget(
      _wrap(
        KynzaButton(label: 'Continuer', isLoading: true, onPressed: () {}),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(KynzaButton),
      matchesGoldenFile('goldens/kynza_button_primary_loading.png'),
    );
  });
}
