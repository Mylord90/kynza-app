import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/user_role.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/providers/auth_providers.dart';
import 'package:kynza/features/auth/application/notifiers/auth_notifier.dart';
import 'package:kynza/features/auth/application/providers/auth_notifier_provider.dart';
import 'package:kynza/features/auth/domain/states/auth_ui_state.dart';
import 'package:kynza/features/home_staff/presentation/screens/home_staff_screen.dart';
import 'package:kynza/l10n/app_localizations.dart';

/// Never touches real Supabase: signOut() just records the call and flips
/// local state, same shape as splash_screen_test.dart's _FixedAuthNotifier
/// but with signOut overridden too, since that's what's under test here.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);

  final AuthUiState _initial;
  bool signOutCalled = false;

  @override
  Future<AuthUiState> build() async => _initial;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const AsyncData(AuthUiState.unauthenticated());
  }
}

const _staffProfile = UserProfile(
  id: 'staff-1',
  role: UserRole.staff,
  fullName: 'Aline Nkurunziza',
  email: 'aline@example.com',
  emailVerified: true,
  profileCompleted: true,
);

Widget _wrap(_FakeAuthNotifier authNotifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => authNotifier),
      currentUserProfileProvider.overrideWith((ref) async => _staffProfile),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StaffAccountSheet()),
    ),
  );
}

void main() {
  group('StaffAccountSheet', () {
    testWidgets('shows the signed-in staff name and email', (tester) async {
      await tester.pumpWidget(_wrap(_FakeAuthNotifier(const AuthUiState.unauthenticated())));
      await tester.pumpAndSettle();

      expect(find.text('Aline Nkurunziza'), findsOneWidget);
      expect(find.text('aline@example.com'), findsOneWidget);
    });

    testWidgets(
      'cancelling the confirm dialog does not sign out',
      (tester) async {
        final authNotifier = _FakeAuthNotifier(
          const AuthUiState.unauthenticated(),
        );
        await tester.pumpWidget(_wrap(authNotifier));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se déconnecter').first);
        await tester.pumpAndSettle();
        // Dialog is up: "Se déconnecter" (confirm) + "Annuler" (cancel).
        expect(find.text('Annuler'), findsOneWidget);

        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();

        expect(authNotifier.signOutCalled, isFalse);
      },
    );

    testWidgets(
      'confirming the dialog signs out exactly once',
      (tester) async {
        final authNotifier = _FakeAuthNotifier(
          const AuthUiState.unauthenticated(),
        );
        await tester.pumpWidget(_wrap(authNotifier));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se déconnecter').first);
        await tester.pumpAndSettle();

        // Both the sheet's own button and the dialog's confirm button read
        // "Se déconnecter" — the dialog's is added last, on top.
        await tester.tap(find.text('Se déconnecter').last);
        await tester.pumpAndSettle();

        expect(authNotifier.signOutCalled, isTrue);
      },
    );
  });
}
