import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/utils/linear_regression.dart';

void main() {
  group('LinearRegression.fit', () {
    test('fits a perfect line exactly', () {
      final result = LinearRegression.fit([0, 1, 2, 3], [10, 20, 30, 40]);
      expect(result.slope, closeTo(10, 0.0001));
      expect(result.intercept, closeTo(10, 0.0001));
    });

    test('fits a flat (zero-slope) series', () {
      final result = LinearRegression.fit([0, 1, 2, 3], [5, 5, 5, 5]);
      expect(result.slope, closeTo(0, 0.0001));
      expect(result.intercept, closeTo(5, 0.0001));
    });

    test('handles a negative trend', () {
      final result = LinearRegression.fit([0, 1, 2], [100, 90, 80]);
      expect(result.slope, closeTo(-10, 0.0001));
      expect(result.intercept, closeTo(100, 0.0001));
    });

    test('returns zero slope/intercept for an empty series', () {
      final result = LinearRegression.fit([], []);
      expect(result.slope, 0);
      expect(result.intercept, 0);
    });

    test(
      'falls back to the mean when every x is identical (zero denominator)',
      () {
        final result = LinearRegression.fit([5, 5, 5], [1, 2, 3]);
        expect(result.slope, 0);
        expect(result.intercept, closeTo(2, 0.0001));
      },
    );

    test('extrapolates beyond the input range along the fitted line', () {
      final result = LinearRegression.fit([0, 1, 2, 3], [10, 20, 30, 40]);
      final predictedAtX10 = result.slope * 10 + result.intercept;
      expect(predictedAtX10, closeTo(110, 0.0001));
    });
  });
}
