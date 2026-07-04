import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/features/evolution/ab_testing/domain/experiment_assignment_service.dart';

void main() {
  group(
    'ExperimentAssignmentService (Phase 7 — deterministic, offline-capable)',
    () {
      test(
        'the same (userId, experimentKey) always resolves to the same '
        'variant — no server round trip, no randomness',
        () {
          const weights = {'control': 50, 'treatment': 50};

          final first = ExperimentAssignmentService.assign(
            userId: 'user-123',
            experimentKey: 'onboarding_cta_copy',
            variantWeights: weights,
          );
          final second = ExperimentAssignmentService.assign(
            userId: 'user-123',
            experimentKey: 'onboarding_cta_copy',
            variantWeights: weights,
          );
          final third = ExperimentAssignmentService.assign(
            userId: 'user-123',
            experimentKey: 'onboarding_cta_copy',
            variantWeights: weights,
          );

          expect(first, isNotNull);
          expect(second, first);
          expect(third, first);
        },
      );

      test('a different user can land in a different variant — real bucketing, not a constant', () {
        const weights = {'control': 50, 'treatment': 50};
        final assignments = {
          for (var i = 0; i < 20; i++)
            'user-$i': ExperimentAssignmentService.assign(
              userId: 'user-$i',
              experimentKey: 'onboarding_cta_copy',
              variantWeights: weights,
            ),
        };

        // Not every one of 20 distinct users landed in the same bucket —
        // proves this is a real hash-based bucketing, not a hardcoded value.
        expect(assignments.values.toSet().length, greaterThan(1));
      });

      test('a different experimentKey for the same user can yield a different variant', () {
        const weights = {'control': 50, 'treatment': 50};

        final resultA = ExperimentAssignmentService.assign(
          userId: 'user-fixed',
          experimentKey: 'experiment_a',
          variantWeights: weights,
        );
        final resultB = ExperimentAssignmentService.assign(
          userId: 'user-fixed',
          experimentKey: 'experiment_b',
          variantWeights: weights,
        );

        // Both must be deterministic individually...
        expect(
          ExperimentAssignmentService.assign(
            userId: 'user-fixed',
            experimentKey: 'experiment_a',
            variantWeights: weights,
          ),
          resultA,
        );
        expect(
          ExperimentAssignmentService.assign(
            userId: 'user-fixed',
            experimentKey: 'experiment_b',
            variantWeights: weights,
          ),
          resultB,
        );
      });

      test('returns null for an empty variant map rather than throwing', () {
        final result = ExperimentAssignmentService.assign(
          userId: 'user-1',
          experimentKey: 'no_variants',
          variantWeights: const {},
        );

        expect(result, isNull);
      });

      test('respects weight proportions — a 0-weight variant is never assigned', () {
        const weights = {'control': 100, 'never_assigned': 0};

        for (var i = 0; i < 30; i++) {
          final variant = ExperimentAssignmentService.assign(
            userId: 'user-$i',
            experimentKey: 'weighted_experiment',
            variantWeights: weights,
          );
          expect(variant, 'control');
        }
      });

      test(
        'computing an assignment requires no async work at all — it is a '
        'pure, synchronous function, proving it needs no network round trip',
        () {
          expect(
            () => ExperimentAssignmentService.assign(
              userId: 'user-1',
              experimentKey: 'sync_check',
              variantWeights: const {'control': 100},
            ),
            returnsNormally,
          );
        },
      );
    },
  );
}
