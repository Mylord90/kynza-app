import '../../domain/models/maps_models.dart';
import '../../domain/repositories/directions_repository.dart';

/// Gated + inert (Phase 7 scaffold) — see
/// `PlacesAutocompleteRepositoryImpl`'s doc comment for the shared
/// rationale (double gate, no SDK wired regardless).
class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl({required this.isEnabled});

  final Future<bool> Function() isEnabled;

  @override
  Future<DirectionsResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    if (!await isEnabled()) return null;
    throw UnimplementedError(
      'Directions has no SDK wired up yet — see '
      'docs/GOOGLE_MAPS_ARCHITECTURE.md for the activation procedure.',
    );
  }
}
