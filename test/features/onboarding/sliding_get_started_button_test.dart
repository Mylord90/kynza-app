import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/onboarding/presentation/widgets/sliding_get_started_button.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SlidingGetStartedButton', () {
    testWidgets('calls onPressed only after the slide/bounce animation completes', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          SlidingGetStartedButton(label: 'Commencer', onPressed: () => pressed = true),
        ),
      );

      await tester.tap(find.byType(SlidingGetStartedButton));
      await tester.pump();
      expect(pressed, isFalse);

      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('Reduce Motion calls onPressed immediately on tap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          SlidingGetStartedButton(label: 'Commencer', onPressed: () => pressed = true),
          disableAnimations: true,
        ),
      );

      await tester.tap(find.byType(SlidingGetStartedButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('exposes a button semantic with the label text', (tester) async {
      await tester.pumpWidget(
        _wrap(SlidingGetStartedButton(label: 'Commencer', onPressed: () {})),
      );

      final semantics = tester.getSemantics(find.byType(SlidingGetStartedButton));
      expect(semantics.label, 'Commencer');
      expect(semantics.getSemanticsData().flagsCollection.isButton, isTrue);
    });
  });
}
