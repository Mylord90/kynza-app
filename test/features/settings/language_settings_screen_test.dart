import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/localization/models/language_enum.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';

/// Wraps [child] with the minimum providers needed to render
/// [LanguageSettingsScreen] without touching Supabase / Hive.
Widget _buildTestApp({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: child,
    ),
  );
}

/// Minimal notifier that never touches Hive / Supabase.
class _FakeLanguageNotifier extends LanguageNotifier {
  _FakeLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;

  // Track the last code set via setLanguage
  String? lastSetCode;

  @override
  void setLanguage(String code) {
    lastSetCode = code;
    state = code;
  }
}

/// Returns an override for [languageProvider] backed by [_FakeLanguageNotifier].
Override _languageOverride(String code) {
  return languageProvider.overrideWith(() => _FakeLanguageNotifier(code));
}

/// Override for [connectivityProvider] — always "connected" so the
/// offline banner stays invisible.
final _connectivityOverride = connectivityProvider.overrideWith(
  (ref) => Stream.value(true),
);

void main() {
  group('LanguageSettingsScreen', () {
    testWidgets('displays one tile for every AppLanguage value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [_languageOverride('fr'), _connectivityOverride],
          child: const LanguageSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      for (final lang in AppLanguage.values) {
        // Match only the title (body style), not the subtitle which may share the same text.
        expect(
          find.descendant(
            of: find.byType(ListTile),
            matching: find.text(lang.nativeName),
          ),
          findsAtLeastNWidgets(1),
        );
      }
    });

    testWidgets('shows check_circle icon for the selected language only', (
      tester,
    ) async {
      const selectedCode = 'en';
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [_languageOverride(selectedCode), _connectivityOverride],
          child: const LanguageSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Should have exactly as many check_circle icons as selected languages (1).
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // All other languages show the unselected icon.
      expect(
        find.byIcon(Icons.circle_outlined),
        findsNWidgets(AppLanguage.values.length - 1),
      );
    });

    testWidgets('tapping a non-selected language calls setLanguage', (
      tester,
    ) async {
      // Start with French selected.
      final notifier = _FakeLanguageNotifier('fr');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(() => notifier),
            _connectivityOverride,
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: LanguageSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap English tile — use first() because nativeName == englishName for English,
      // so find.text finds both the title and subtitle Text widgets.
      await tester.tap(find.text(AppLanguage.english.nativeName).first);

      await tester.pumpAndSettle();

      expect(notifier.lastSetCode, AppLanguage.english.code);
    });

    testWidgets(
      'tapping the currently selected language does NOT call setLanguage',
      (tester) async {
        final notifier = _FakeLanguageNotifier('fr');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              languageProvider.overrideWith(() => notifier),
              _connectivityOverride,
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('fr'),
              home: LanguageSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap French tile — same as current selection.
        await tester.tap(find.text(AppLanguage.french.nativeName));
        await tester.pumpAndSettle();

        expect(notifier.lastSetCode, isNull);
      },
    );

    testWidgets('AppBar title matches the settingsLanguageTitle l10n key', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [_languageOverride('fr'), _connectivityOverride],
          child: const LanguageSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // The French value for settingsLanguageTitle is "Langue".
      expect(find.widgetWithText(AppBar, 'Langue'), findsOneWidget);
    });
  });
}
