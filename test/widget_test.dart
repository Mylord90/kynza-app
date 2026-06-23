import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/utils/currency_formatter.dart';
import 'package:kynza/core/utils/validators.dart';
import 'package:kynza/shared/widgets/kynza_button.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats BIF with narrow-space thousands separator', () {
      expect(CurrencyFormatter.formatBif(45000), '45 000 FBu');
    });

    test('formats negative amounts with a leading minus', () {
      expect(CurrencyFormatter.formatBif(-1500), '-1 500 FBu');
    });

    test('round-trips formatBif/parseBif', () {
      expect(
        CurrencyFormatter.parseBif(CurrencyFormatter.formatBif(123456)),
        123456,
      );
    });

    test('confidential mode masks the amount', () {
      expect(CurrencyFormatter.confidential(), '••••• FBu');
    });
  });

  group('Validators', () {
    test('rejects passwords without a digit', () {
      expect(Validators.password('Abcdefgh'), isNotNull);
    });

    test('accepts a valid password', () {
      expect(Validators.password('Abcdefg1'), isNull);
    });

    test('requires exactly 8 digits for phone numbers', () {
      expect(Validators.phone('1234567'), isNotNull);
      expect(Validators.phone('12345678'), isNull);
    });
  });

  testWidgets(
    'KynzaButton shows a spinner instead of its label while loading',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KynzaButton(
              label: 'Continuer',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Continuer'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
