import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/presentation/widgets/onboarding_sign_in_link.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('OnboardingSignInLink', () {
    testWidgets('calls onPressed only after the opacity flash completes', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          OnboardingSignInLink(
            question: 'Vous avez déjà un compte ?',
            accent: 'Se connecter',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(OnboardingSignInLink));
      await tester.pump();
      expect(pressed, isFalse);

      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('Reduce Motion calls onPressed immediately on tap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          OnboardingSignInLink(
            question: 'Vous avez déjà un compte ?',
            accent: 'Se connecter',
            onPressed: () => pressed = true,
          ),
          disableAnimations: true,
        ),
      );

      await tester.tap(find.byType(OnboardingSignInLink));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('exposes a single merged button semantic with question + accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingSignInLink(
            question: 'Vous avez déjà un compte ?',
            accent: 'Se connecter',
            onPressed: () {},
            semanticHint: 'Ouvre l\'écran de connexion',
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(OnboardingSignInLink));
      expect(semantics.label, 'Vous avez déjà un compte ? Se connecter');
      expect(semantics.hint, 'Ouvre l\'écran de connexion');
      expect(semantics.getSemanticsData().flagsCollection.isButton, isTrue);
    });

    testWidgets('meets the 48dp minimum tap target height', (tester) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingSignInLink(
            question: 'Vous avez déjà un compte ?',
            accent: 'Se connecter',
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(ConstrainedBox).first);
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('underlines on desktop mouse hover, not otherwise', (tester) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingSignInLink(
            question: 'Vous avez déjà un compte ?',
            accent: 'Se connecter',
            onPressed: () {},
          ),
        ),
      );

      Text richText() => tester.widget<Text>(find.byType(Text));
      TextSpan span() => richText().textSpan as TextSpan;

      expect(
        (span().children!.first as TextSpan).style!.decoration,
        TextDecoration.none,
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(OnboardingSignInLink)));
      await tester.pump();

      expect(
        (span().children!.first as TextSpan).style!.decoration,
        TextDecoration.underline,
      );
    });
  });
}
