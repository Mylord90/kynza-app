import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/constants/env.dart';
import 'package:kynza/core/security/app_check_feature_gate.dart';
import 'package:kynza/core/security/app_check_service.dart';
import 'package:kynza/features/evolution/feature_flags/application/providers/feature_flag_providers.dart';

void main() {
  group('AppCheckFeatureGate — inert by default (Phase 10 scaffold)', () {
    test('isOptedIn is false — no --dart-define=APP_CHECK_ENABLED=true anywhere', () {
      expect(Env.appCheckEnabled, isFalse);
      expect(AppCheckFeatureGate.isOptedIn, isFalse);
    });

    test(
      'appCheckEnabledProvider resolves to false WITHOUT ever evaluating '
      'the feature flag — proves the opt-in-absence short-circuit actually '
      'runs, not just that the end result happens to be false',
      () async {
        final container = ProviderContainer(
          overrides: [
            featureFlagEvaluationProvider('feature_app_check').overrideWith(
              (ref) => Future<bool>.error(
                'should never be evaluated when APP_CHECK_ENABLED is not set',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final enabled = await container.read(appCheckEnabledProvider.future);

        expect(enabled, isFalse);
      },
    );
  });

  group('AppCheckService.headers — inert by default', () {
    test('returns an empty header map when the gate is off', () async {
      final headers = await AppCheckService.headers();
      expect(headers, isEmpty);
    });
  });
}
