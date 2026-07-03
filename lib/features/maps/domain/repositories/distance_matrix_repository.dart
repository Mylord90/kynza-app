import '../models/maps_models.dart';

/// Requires GOOGLE_MAPS_API_KEY in Vault, currently unset, and the Google
/// Distance Matrix SDK, not yet a pubspec dependency — see
/// docs/GOOGLE_MAPS_ARCHITECTURE.md before implementing.
abstract class DistanceMatrixRepository {
  /// [destinations] is a list of (lat, lng) pairs; results are returned in
  /// the same order, addressed by [DistanceMatrixResult.destinationIndex]
  /// so a caller can match a result back to the destination it asked about
  /// even if the underlying API ever returns them out of order.
  Future<List<DistanceMatrixResult>> getDistances({
    required double originLat,
    required double originLng,
    required List<(double lat, double lng)> destinations,
  });
}
