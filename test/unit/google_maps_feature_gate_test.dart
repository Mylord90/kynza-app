import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/constants/env.dart';
import 'package:kynza/features/evolution/feature_flags/application/providers/feature_flag_providers.dart';
import 'package:kynza/features/maps/application/google_maps_feature_gate.dart';

void main() {
  group('GoogleMapsFeatureGate — inert by default (Phase 7 scaffold)', () {
    test('hasApiKey is false — no key is configured anywhere in this repo', () {
      expect(Env.googleMapsApiKey, isEmpty);
      expect(GoogleMapsFeatureGate.hasApiKey, isFalse);
    });

    test(
      'googleMapsEnabledProvider resolves to false WITHOUT ever evaluating '
      'the feature flag — proves the key-absence short-circuit actually '
      'runs, not just that the end result happens to be false',
      () async {
        final container = ProviderContainer(
          overrides: [
            // If googleMapsEnabledProvider ever read this provider despite
            // no API key being configured, this override would throw and
            // fail the test — proving the short-circuit is real.
            featureFlagEvaluationProvider('feature_google_maps').overrideWith(
              (ref) => Future<bool>.error(
                'should never be evaluated when no API key is configured',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final enabled = await container.read(googleMapsEnabledProvider.future);

        expect(enabled, isFalse);
      },
    );
  });
}
