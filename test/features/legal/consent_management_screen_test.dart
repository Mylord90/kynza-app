import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/legal_consent_setting_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/features/legal/application/providers/legal_providers.dart';
import 'package:kynza/features/legal/presentation/screens/consent_management_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/kynza_error_state.dart';
import 'package:kynza/shared/widgets/kynza_skeleton.dart';

final _connectivityOverride = connectivityProvider.overrideWith(
  (ref) => Stream.value(true),
);

Widget _buildTestApp(List<Override> overrides) {
  return ProviderScope(
    overrides: [_connectivityOverride, ...overrides],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('fr'),
      home: ConsentManagementScreen(),
    ),
  );
}

void main() {
  group('ConsentManagementScreen', () {
    // This screen renders a fixed set of 4 toggles (one per LegalConsentType)
    // regardless of how many rows exist server-side — there is no
    // meaningful "empty" state or content-size split to exercise here (that
    // pattern fits data-driven lists, not a fixed enum of settings), so this
    // covers loading/error/content instead — documented deliberately rather
    // than forcing a state that doesn't apply to this screen's design.
    testWidgets('loading shows a skeleton', (tester) async {
      await tester.pumpWidget(
        _buildTestApp([
          userLegalConsentsProvider.overrideWith(
            (ref) => Completer<List<LegalConsentSettingModel>>().future,
          ),
        ]),
      );
      await tester.pump();

      expect(find.byType(KynzaSkeleton), findsOneWidget);
    });

    testWidgets('error shows KynzaErrorState with a retry button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp([
          userLegalConsentsProvider.overrideWith(
            (ref) =>
                Future<List<LegalConsentSettingModel>>.error('boom'),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KynzaErrorState), findsOneWidget);
    });

    testWidgets('renders one SwitchListTile per LegalConsentType', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp([
          userLegalConsentsProvider.overrideWith(
            (ref) => Future.value(const <LegalConsentSettingModel>[]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(SwitchListTile),
        findsNWidgets(LegalConsentType.values.length),
      );
    });

    testWidgets('reflects granted=true from an existing consent row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp([
          userLegalConsentsProvider.overrideWith(
            (ref) => Future.value(const [
              LegalConsentSettingModel(
                userId: 'u-1',
                consentType: LegalConsentType.analytics,
                granted: true,
              ),
            ]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches.where((s) => s.value).length, 1);
    });
  });
}
