import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/legal_document_model.dart';
import 'package:kynza/core/models/legal/legal_document_version_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/features/legal/application/providers/legal_providers.dart';
import 'package:kynza/features/legal/presentation/screens/policy_viewer_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/kynza_error_state.dart';
import 'package:kynza/shared/widgets/kynza_skeleton.dart';

const _slug = 'privacy-policy';

const _document = LegalDocumentModel(
  id: 'doc-1',
  slug: _slug,
  type: LegalDocumentType.privacyPolicy,
);

const _version = LegalDocumentVersionModel(
  id: 'v-1',
  documentId: 'doc-1',
  versionNumber: 1,
  contentMarkdown: '⚠️ PLACEHOLDER content',
);

final _connectivityOverride = connectivityProvider.overrideWith(
  (ref) => Stream.value(true),
);

Widget _buildTestApp(List<Override> overrides) {
  return ProviderScope(
    overrides: [..._overridesBase(), ...overrides],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('fr'),
      home: PolicyViewerScreen(slug: _slug),
    ),
  );
}

List<Override> _overridesBase() => [_connectivityOverride];

void main() {
  group('PolicyViewerScreen — 5 render states', () {
    testWidgets('loading shows a skeleton', (tester) async {
      await tester.pumpWidget(
        _buildTestApp([
          policyViewerDataProvider(
            _slug,
          ).overrideWith((ref) => Completer<PolicyViewerData?>().future),
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
          policyViewerDataProvider(
            _slug,
          ).overrideWith((ref) => Future<PolicyViewerData?>.error('boom')),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KynzaErrorState), findsOneWidget);
    });

    testWidgets(
      'a null document/version bundle also renders KynzaErrorState',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp([
            policyViewerDataProvider(
              _slug,
            ).overrideWith((ref) => Future.value(null)),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KynzaErrorState), findsOneWidget);
      },
    );

    testWidgets('not yet accepted shows the accept button, not the badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp([
          policyViewerDataProvider(_slug).overrideWith(
            (ref) => Future.value(
              const PolicyViewerData(
                document: _document,
                version: _version,
                isAccepted: false,
              ),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('J\'accepte'), findsOneWidget);
      expect(find.text('Déjà accepté'), findsNothing);
    });

    testWidgets('already accepted shows the accepted badge, not the button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp([
          policyViewerDataProvider(_slug).overrideWith(
            (ref) => Future.value(
              const PolicyViewerData(
                document: _document,
                version: _version,
                isAccepted: true,
              ),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Déjà accepté'), findsOneWidget);
      expect(find.text('J\'accepte'), findsNothing);
    });
  });
}
