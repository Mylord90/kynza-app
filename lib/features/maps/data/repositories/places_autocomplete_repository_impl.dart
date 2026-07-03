import '../../domain/models/maps_models.dart';
import '../../domain/repositories/places_autocomplete_repository.dart';

/// Gated + inert (Phase 7 scaffold). [isEnabled] is checked first so the
/// method returns an empty result with zero network activity whenever the
/// double gate (`GoogleMapsFeatureGate`) is off — which is always, today.
/// Even in the hypothetical case [isEnabled] returned true, there is still
/// no Places SDK wired up to actually call — see the class-level doc
/// comment on `PlacesAutocompleteRepository` for the activation procedure.
class PlacesAutocompleteRepositoryImpl implements PlacesAutocompleteRepository {
  PlacesAutocompleteRepositoryImpl({required this.isEnabled});

  final Future<bool> Function() isEnabled;

  @override
  Future<List<PlacePrediction>> autocomplete(String query) async {
    if (!await isEnabled()) return const [];
    throw UnimplementedError(
      'Places Autocomplete has no SDK wired up yet — see '
      'docs/GOOGLE_MAPS_ARCHITECTURE.md for the activation procedure.',
    );
  }
}
