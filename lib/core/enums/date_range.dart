/// Dashboard analytics period selector (kynza-uiux-design-system.md §4 —
/// KynzaPeriodSelector). `custom` is reserved for a future date-range
/// picker and is not wired to any UI control yet.
enum DateRange { today, last7days, last30days, custom }

extension DateRangeX on DateRange {
  String get label => switch (this) {
    DateRange.today => "Aujourd'hui",
    DateRange.last7days => '7 jours',
    DateRange.last30days => '30 jours',
    DateRange.custom => 'Personnalisé',
  };

  int get days => switch (this) {
    DateRange.today => 1,
    DateRange.last7days => 7,
    DateRange.last30days => 30,
    DateRange.custom => 30,
  };
}
