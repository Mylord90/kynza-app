import '../models/maps_models.dart';

/// Requires GOOGLE_MAPS_API_KEY in Vault, currently unset, and the Google
/// Geocoding SDK, not yet a pubspec dependency — see
/// docs/GOOGLE_MAPS_ARCHITECTURE.md before implementing.
abstract class GeocodingRepository {
  Future<GeocodeResult?> geocode(String address);
  Future<GeocodeResult?> reverseGeocode(double latitude, double longitude);
}
