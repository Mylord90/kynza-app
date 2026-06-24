import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/date_range.dart';
import 'package:kynza/core/utils/trend_calculator.dart';

void main() {
  group('TrendCalculator.percentChange', () {
    test('returns a positive percentage when current exceeds previous', () {
      expect(TrendCalculator.percentChange(150, 100), 50);
    });

    test('returns a negative percentage when current is below previous', () {
      expect(TrendCalculator.percentChange(80, 100), -20);
    });

    test(
      'returns null when there is no previous baseline (division by zero)',
      () {
        expect(TrendCalculator.percentChange(100, 0), null);
      },
    );

    test('returns 0 when current equals previous', () {
      expect(TrendCalculator.percentChange(100, 100), 0);
    });
  });

  group('DateRangeX', () {
    test('days maps each period to its window length', () {
      expect(DateRange.today.days, 1);
      expect(DateRange.last7days.days, 7);
      expect(DateRange.last30days.days, 30);
    });

    test('label is a human-readable French string', () {
      expect(DateRange.today.label, "Aujourd'hui");
      expect(DateRange.last7days.label, '7 jours');
      expect(DateRange.last30days.label, '30 jours');
    });
  });
}
