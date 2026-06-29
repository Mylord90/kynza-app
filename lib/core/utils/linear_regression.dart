/// Ordinary least-squares fit over (x, y) pairs — used by
/// AnalyticsRepository.getRevenueForecast to project trailing weekly
/// revenue forward. Pulled out as a pure utility (alongside
/// TrendCalculator/CurrencyFormatter) so the math is testable without a
/// Supabase-backed repository test.
abstract class LinearRegression {
  static ({double slope, double intercept}) fit(
    List<double> xs,
    List<double> ys,
  ) {
    final n = xs.length;
    if (n == 0) return (slope: 0, intercept: 0);

    final sumX = xs.fold(0.0, (a, b) => a + b);
    final sumY = ys.fold(0.0, (a, b) => a + b);
    var sumXY = 0.0;
    var sumX2 = 0.0;
    for (var i = 0; i < n; i++) {
      sumXY += xs[i] * ys[i];
      sumX2 += xs[i] * xs[i];
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return (slope: 0, intercept: sumY / n);

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    return (slope: slope, intercept: intercept);
  }
}
