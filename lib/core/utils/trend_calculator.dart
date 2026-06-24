/// Pure period-over-period trend math — extracted out of
/// AnalyticsRepositoryImpl so it stays unit-testable without a Supabase
/// double (no mocking package exists in this project yet, cf.
/// kynza-testing-quality.md §1: pure logic tests are the default).
abstract class TrendCalculator {
  /// Percentage change from [previous] to [current], rounded to the
  /// nearest integer. Returns null when there is no previous baseline to
  /// compare against (division by zero is undefined, not "0% change" or
  /// "+100%" — both would be misleading on a dashboard).
  static int? percentChange(num current, num previous) {
    if (previous == 0) return null;
    return (((current - previous) / previous) * 100).round();
  }
}
