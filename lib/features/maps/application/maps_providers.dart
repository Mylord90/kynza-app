import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/directions_repository_impl.dart';
import '../data/repositories/distance_matrix_repository_impl.dart';
import '../data/repositories/geocoding_repository_impl.dart';
import '../data/repositories/places_autocomplete_repository_impl.dart';
import '../domain/repositories/directions_repository.dart';
import '../domain/repositories/distance_matrix_repository.dart';
import '../domain/repositories/geocoding_repository.dart';
import '../domain/repositories/places_autocomplete_repository.dart';
import 'google_maps_feature_gate.dart';

Future<bool> Function() _gateCheckerFor(Ref ref) =>
    () => ref.read(googleMapsEnabledProvider.future);

final placesAutocompleteRepositoryProvider =
    Provider<PlacesAutocompleteRepository>(
      (ref) => PlacesAutocompleteRepositoryImpl(isEnabled: _gateCheckerFor(ref)),
    );

final geocodingRepositoryProvider = Provider<GeocodingRepository>(
  (ref) => GeocodingRepositoryImpl(isEnabled: _gateCheckerFor(ref)),
);

final directionsRepositoryProvider = Provider<DirectionsRepository>(
  (ref) => DirectionsRepositoryImpl(isEnabled: _gateCheckerFor(ref)),
);

final distanceMatrixRepositoryProvider = Provider<DistanceMatrixRepository>(
  (ref) => DistanceMatrixRepositoryImpl(isEnabled: _gateCheckerFor(ref)),
);
