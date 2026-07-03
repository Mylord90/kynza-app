import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/legal_consent_setting_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/features/legal/application/providers/legal_providers.dart';
import 'package:kynza/features/legal/presentation/screens/consent_management_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/kynza_button.dart';
import 'package:kynza/shared/widgets/kynza_empty_state.dart';

/// Automated semantic-tree accessibility assertions using flutter_test's
/// built-in `AccessibilityGuideline` API (`meetsGuideline` +
/// `textContrastGuideline`/`androidTapTargetGuideline`/
/// `iOSTapTargetGuideline`/`labeledTapTargetGuideline`) — shipped in the
/// Flutter SDK itself, no external dependency needed. This replaces manual
/// TalkBack passes with a real, repeatable, CI-runnable check (Phase 9,
/// Enterprise Hardening pass). Covers a shared widget used everywhere
/// (KynzaButton), a shared layout widget (KynzaEmptyState), and one real
/// full screen (ConsentManagementScreen, reusing the fakes already
/// established in test/features/legal/consent_management_screen_test.dart).
final _connectivityOverride = connectivityProvider.overrideWith(
  (ref) => Stream.value(true),
);

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(backgroundColor: const Color(0xFF09090B), body: child),
  );
}

void main() {
  group('Accessibility guidelines — KynzaButton', () {
    testWidgets('primary variant meets tap-target and text-contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Center(
            child: KynzaButton(label: 'Continuer', onPressed: () {}),
          ),
        ),
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('destructive variant meets tap-target and text-contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Center(
            child: KynzaButton(
              label: 'Supprimer',
              variant: KynzaButtonVariant.destructive,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Accessibility guidelines — KynzaEmptyState', () {
    testWidgets('meets tap-target and text-contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
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

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Accessibility guidelines — ConsentManagementScreen (real screen)', () {
    testWidgets('content state meets tap-target and text-contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectivityOverride,
            userLegalConsentsProvider.overrideWith(
              (ref) => Future.value(const <LegalConsentSettingModel>[]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: ConsentManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(SwitchListTile),
        findsNWidgets(LegalConsentType.values.length),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
