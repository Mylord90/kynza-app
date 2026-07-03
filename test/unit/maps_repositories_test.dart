import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/maps/data/repositories/directions_repository_impl.dart';
import 'package:kynza/features/maps/data/repositories/distance_matrix_repository_impl.dart';
import 'package:kynza/features/maps/data/repositories/geocoding_repository_impl.dart';
import 'package:kynza/features/maps/data/repositories/places_autocomplete_repository_impl.dart';

Future<bool> _disabled() async => false;
Future<bool> _enabled() async => true;

void main() {
  group('Maps repositories — gated + inert (Phase 7 scaffold)', () {
    test('PlacesAutocompleteRepository returns empty, no throw, when disabled', () async {
      final repo = PlacesAutocompleteRepositoryImpl(isEnabled: _disabled);
      expect(await repo.autocomplete('some query'), isEmpty);
    });

    test('GeocodingRepository returns null, no throw, when disabled', () async {
      final repo = GeocodingRepositoryImpl(isEnabled: _disabled);
      expect(await repo.geocode('some address'), isNull);
      expect(await repo.reverseGeocode(0, 0), isNull);
    });

    test('DirectionsRepository returns null, no throw, when disabled', () async {
      final repo = DirectionsRepositoryImpl(isEnabled: _disabled);
      expect(
        await repo.getRoute(
          originLat: 0,
          originLng: 0,
          destinationLat: 1,
          destinationLng: 1,
        ),
        isNull,
      );
    });

    test('DistanceMatrixRepository returns empty, no throw, when disabled', () async {
      final repo = DistanceMatrixRepositoryImpl(isEnabled: _disabled);
      expect(
        await repo.getDistances(originLat: 0, originLng: 0, destinations: const []),
        isEmpty,
      );
    });

    test(
      'even if the gate were somehow enabled, every repository still has '
      'no SDK to call — throws UnimplementedError, never attempts a '
      'network request (proves the scaffold cannot silently activate)',
      () async {
        expect(
          () => PlacesAutocompleteRepositoryImpl(isEnabled: _enabled)
              .autocomplete('x'),
          throwsUnimplementedError,
        );
        expect(
          () => GeocodingRepositoryImpl(isEnabled: _enabled).geocode('x'),
          throwsUnimplementedError,
        );
        expect(
          () => DirectionsRepositoryImpl(isEnabled: _enabled).getRoute(
            originLat: 0,
            originLng: 0,
            destinationLat: 1,
            destinationLng: 1,
          ),
          throwsUnimplementedError,
        );
        expect(
          () => DistanceMatrixRepositoryImpl(isEnabled: _enabled).getDistances(
            originLat: 0,
            originLng: 0,
            destinations: const [],
          ),
          throwsUnimplementedError,
        );
      },
    );
  });
}
