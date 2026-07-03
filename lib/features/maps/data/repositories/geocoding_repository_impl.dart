import '../../domain/models/maps_models.dart';
import '../../domain/repositories/geocoding_repository.dart';

/// Gated + inert (Phase 7 scaffold) — see
/// `PlacesAutocompleteRepositoryImpl`'s doc comment for the shared
/// rationale (double gate, no SDK wired regardless).
class GeocodingRepositoryImpl implements GeocodingRepository {
  GeocodingRepositoryImpl({required this.isEnabled});

  final Future<bool> Function() isEnabled;

  @override
  Future<GeocodeResult?> geocode(String address) async {
    if (!await isEnabled()) return null;
    throw UnimplementedError(
      'Geocoding has no SDK wired up yet — see '
      'docs/GOOGLE_MAPS_ARCHITECTURE.md for the activation procedure.',
    );
  }

  @override
  Future<GeocodeResult?> reverseGeocode(double latitude, double longitude) async {
    if (!await isEnabled()) return null;
    throw UnimplementedError(
      'Reverse geocoding has no SDK wired up yet — see '
      'docs/GOOGLE_MAPS_ARCHITECTURE.md for the activation procedure.',
    );
  }
}
