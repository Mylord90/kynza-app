import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/kynza_empty_state.dart';

/// Golden references live under `test/golden/goldens/`. Regenerate with
/// `flutter test --update-goldens test/golden/kynza_empty_state_golden_test.dart`
/// — a human must eyeball new PNGs once before trusting them as the
/// baseline (Phase 9, Enterprise Hardening pass).
Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(backgroundColor: const Color(0xFF09090B), body: child),
  );
}

void main() {
  testWidgets('KynzaEmptyState with a default icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        KynzaEmptyState(
          icon: Icons.event_note_outlined,
          title: 'Aucune réservation',
          subtitle: 'Réservez votre premier rendez-vous beauté.',
          ctaLabel: 'Découvrir',
          onCta: () {},
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(KynzaEmptyState),
      matchesGoldenFile('goldens/kynza_empty_state_default_icon.png'),
    );
  });
}
