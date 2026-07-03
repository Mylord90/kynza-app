import '../../domain/models/maps_models.dart';
import '../../domain/repositories/distance_matrix_repository.dart';

/// Gated + inert (Phase 7 scaffold) — see
/// `PlacesAutocompleteRepositoryImpl`'s doc comment for the shared
/// rationale (double gate, no SDK wired regardless).
class DistanceMatrixRepositoryImpl implements DistanceMatrixRepository {
  DistanceMatrixRepositoryImpl({required this.isEnabled});

  final Future<bool> Function() isEnabled;

  @override
  Future<List<DistanceMatrixResult>> getDistances({
    required double originLat,
    required double originLng,
    required List<(double lat, double lng)> destinations,
  }) async {
    if (!await isEnabled()) return const [];
    throw UnimplementedError(
      'Distance Matrix has no SDK wired up yet — see '
      'docs/GOOGLE_MAPS_ARCHITECTURE.md for the activation procedure.',
    );
  }
}
