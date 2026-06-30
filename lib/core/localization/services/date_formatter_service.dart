import 'package:intl/intl.dart';

/// Locale-aware date formatting. Inject via constructor or use static helpers.
/// All formatting respects the active [locale] so dates display correctly
/// in both French (DD/MM/YYYY) and English (MM/DD/YYYY or similar).
class DateFormatterService {
  const DateFormatterService(this.locale);

  final String locale;

  /// "14 juin 2025" / "June 14, 2025"
  String formatLong(DateTime date) =>
      DateFormat.yMMMMd(locale).format(date);

  /// "14/06/2025" / "06/14/2025"
  String formatShort(DateTime date) =>
      DateFormat.yMd(locale).format(date);

  /// "14 juin" / "June 14"
  String formatDayMonth(DateTime date) =>
      DateFormat.MMMMd(locale).format(date);

  /// "lun. 14 juin" / "Mon, June 14"
  String formatWeekdayDayMonth(DateTime date) =>
      DateFormat.MMMEd(locale).format(date);

  /// "09:30" — time is locale-independent (24 h)
  String formatTime(DateTime date) =>
      DateFormat('HH:mm').format(date);

  /// "09:30 – 10:00"
  String formatTimeRange(DateTime start, DateTime end) =>
      '${formatTime(start)} – ${formatTime(end)}';

  /// "lun. 14 juin · 09:30" / "Mon, June 14 · 09:30"
  String formatAppointment(DateTime date) =>
      '${formatWeekdayDayMonth(date)} · ${formatTime(date)}';

  static DateFormatterService of(String locale) =>
      DateFormatterService(locale);
}
