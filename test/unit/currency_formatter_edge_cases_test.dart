import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/currency_code.dart';
import 'package:kynza/core/utils/currency_formatter.dart';

// formatBif() separates digit groups with U+202F (narrow no-break space),
// not a plain ASCII space — only the space before the "FBu" suffix is
// ordinary. Spelled out via   below so the literals are unambiguous.
const _nbsp = ' ';

void main() {
  group('CurrencyFormatter.formatBif — boundary values', () {
    test('zero', () {
      expect(CurrencyFormatter.formatBif(0), '0 FBu');
    });

    test('just under the first thousands separator', () {
      expect(CurrencyFormatter.formatBif(999), '999 FBu');
    });

    test('exactly one thousand introduces the first separator', () {
      expect(CurrencyFormatter.formatBif(1000), '1${_nbsp}000 FBu');
    });

    test('millions get two thousands separators', () {
      expect(
        CurrencyFormatter.formatBif(1000000),
        '1${_nbsp}000${_nbsp}000 FBu',
      );
    });

    test('a large real-world amount (e.g. a Premium plan invoice)', () {
      expect(CurrencyFormatter.formatBif(125000), '125${_nbsp}000 FBu');
    });
  });

  group('CurrencyFormatter.parseBif — malformed/edge input', () {
    test('empty string parses to 0 instead of throwing', () {
      expect(CurrencyFormatter.parseBif(''), 0);
    });

    test('non-numeric garbage parses to 0 instead of throwing', () {
      expect(CurrencyFormatter.parseBif('abc'), 0);
    });

    test('"0 FBu" parses back to 0', () {
      expect(CurrencyFormatter.parseBif('0 FBu'), 0);
    });

    test(
      'tolerates a plain ASCII space instead of the narrow no-break space',
      () {
        // formatBif emits U+202F; a user re-typing the amount would use a
        // regular space — parseBif must not silently break on that input.
        expect(CurrencyFormatter.parseBif('45 000 FBu'), 45000);
      },
    );

    test('round-trips every formatBif boundary value', () {
      for (final amount in [0, 1, 999, 1000, 45000, 999999, 1000000, 125000]) {
        expect(
          CurrencyFormatter.parseBif(CurrencyFormatter.formatBif(amount)),
          amount,
          reason: 'failed to round-trip $amount',
        );
      }
    });
  });

  group(
    'CurrencyFormatter.format — multi-currency (V2-ready, BIF-only in V1 UI)',
    () {
      test('formats USD with its symbol and 2 decimal digits', () {
        final result = CurrencyFormatter.format(45.5, CurrencyCode.usd);
        expect(result, contains(r'$'));
        expect(result, contains('45.50'));
      });

      test('formats EUR with its symbol', () {
        final result = CurrencyFormatter.format(10, CurrencyCode.eur);
        expect(result, contains('€'));
      });

      test('BIF has zero decimal digits (no fractional FBu in practice)', () {
        expect(CurrencyCode.bif.decimalDigits, 0);
      });
    },
  );

  group('CurrencyFormatter.confidential', () {
    test('always returns the masked placeholder regardless of any amount', () {
      expect(CurrencyFormatter.confidential(), '••••• FBu');
    });
  });
}
