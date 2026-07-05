import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/booking_model.dart';

/// Last-known booking snapshot, cached on-device per stream key (client id,
/// or salon/practitioner id + day) — same "last-cached snapshot, not a
/// blank screen" convention as [CmsCache]/[FeatureFlagCache], adapted for a
/// realtime `.stream()` source instead of a one-shot fetch: a cold app
/// start offline never gets an error from `SupabaseStreamBuilder` to catch
/// (it just never emits), so the read-through happens at the provider level
/// by yielding this cached value immediately, before the live stream's
/// first emission arrives (see booking_providers.dart).
abstract class BookingReadCache {
  static const boxName = 'kynza_booking_cache';

  static Box get _box => Hive.box(boxName);

  static List<BookingModel>? _read(String key) {
    final raw = _box.get(key);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((r) => BookingModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  static Future<void> _write(String key, List<BookingModel> bookings) {
    return _box.put(key, bookings.map((b) => b.toJson()).toList());
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static List<BookingModel>? getClientBookings(String clientId) =>
      _read('client:$clientId');

  static Future<void> setClientBookings(
    String clientId,
    List<BookingModel> bookings,
  ) => _write('client:$clientId', bookings);

  static List<BookingModel>? getSalonBookings(String salonId, DateTime date) =>
      _read('salon:$salonId:${_dayKey(date)}');

  static Future<void> setSalonBookings(
    String salonId,
    DateTime date,
    List<BookingModel> bookings,
  ) => _write('salon:$salonId:${_dayKey(date)}', bookings);

  static List<BookingModel>? getPractitionerBookings(
    String practitionerId,
    DateTime date,
  ) => _read('practitioner:$practitionerId:${_dayKey(date)}');

  static Future<void> setPractitionerBookings(
    String practitionerId,
    DateTime date,
    List<BookingModel> bookings,
  ) => _write('practitioner:$practitionerId:${_dayKey(date)}', bookings);

  static Future<void> clear() => _box.clear();
}
