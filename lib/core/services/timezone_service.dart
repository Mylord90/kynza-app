import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// KYNZA V1 operates exclusively in Burundi (UTC+2, no DST) — every local
/// time shown to a user (working hours, slot pickers, reminders) must be
/// expressed in this timezone, while every DB column stays TIMESTAMPTZ/UTC.
abstract class TimeZoneService {
  static late tz.Location bujumbura;

  static void init() {
    tz_data.initializeTimeZones();
    bujumbura = tz.getLocation('Africa/Bujumbura');
  }

  static DateTime toLocal(DateTime utc) => tz.TZDateTime.from(utc, bujumbura);

  static DateTime toUtc(DateTime local) => tz.TZDateTime(
    bujumbura,
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
  ).toUtc();

  static DateTime nowLocal() => tz.TZDateTime.now(bujumbura);
}
