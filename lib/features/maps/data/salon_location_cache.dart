import 'package:hive_flutter/hive_flutter.dart';

/// Last-known salon coordinates, cached on-device so a salon list/detail
/// view can still show an approximate location when the Google Maps
/// feature is off (always, today) or unreachable — Phase 7 scaffold. No
/// TTL: a salon's coordinates don't go stale the way a permission check
/// does, and a slightly outdated pin is still useful; a fresh value simply
/// overwrites the cached one whenever one is fetched.
///
/// Currently a no-op in practice: `salons.latitude`/`longitude` are never
/// populated by any UI today (the salon creation wizard only collects
/// province/commune + free-text address — see
/// `docs/GOOGLE_MAPS_ARCHITECTURE.md`), so there's nothing real to cache
/// yet. The mechanism is ready for when that changes.
abstract class SalonLocationCache {
  static const boxName = 'kynza_salon_location_cache';

  static Box get _box => Hive.box(boxName);

  static ({double latitude, double longitude})? get(String salonId) {
    final entry = _box.get(salonId);
    if (entry is! Map) return null;
    final lat = entry['latitude'] as double?;
    final lng = entry['longitude'] as double?;
    if (lat == null || lng == null) return null;
    return (latitude: lat, longitude: lng);
  }

  static Future<void> set(
    String salonId, {
    required double latitude,
    required double longitude,
  }) {
    return _box.put(salonId, {'latitude': latitude, 'longitude': longitude});
  }

  static Future<void> clear() => _box.clear();
}
