/// Minimal placeholder result shapes for the Google Maps scaffold (Phase 7)
/// — deliberately NOT modeled after a real API response, since no request
/// has ever actually been made against Google's APIs from this codebase.
/// These exist only so the repository interfaces below have a concrete
/// return type to compile against; expect to reshape them once a real key
/// is supplied and `google_maps_flutter`/places/geocoding SDKs are added.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

class GeocodeResult {
  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
}

class DirectionsResult {
  const DirectionsResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
  });

  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
}

class DistanceMatrixResult {
  const DistanceMatrixResult({
    required this.destinationIndex,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final int destinationIndex;
  final int distanceMeters;
  final int durationSeconds;
}
