import '../models/maps_models.dart';

/// Requires GOOGLE_MAPS_API_KEY in Vault, currently unset, and the Google
/// Directions SDK, not yet a pubspec dependency — see
/// docs/GOOGLE_MAPS_ARCHITECTURE.md before implementing.
abstract class DirectionsRepository {
  Future<DirectionsResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  });
}
