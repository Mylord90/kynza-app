import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/experiment_model.dart';
import '../../../../../core/providers/auth_providers.dart';
import '../../data/repositories/ab_testing_repository_impl.dart';
import '../../domain/experiment_assignment_service.dart';
import '../../domain/repositories/ab_testing_repository.dart';

final abTestingRepositoryProvider = Provider<AbTestingRepository>(
  (ref) => AbTestingRepositoryImpl(),
);

final experimentsProvider = FutureProvider<List<ExperimentModel>>(
  (ref) => ref.read(abTestingRepositoryProvider).getExperiments(),
);

/// Deterministic, offline-capable variant for the current user in
/// [experimentKey] — computed purely client-side via
/// [ExperimentAssignmentService], no network round trip required to know
/// the answer. An experiment variant can gate an existing feature flag
/// (Phase 3) rather than this engine reinventing gating logic — e.g. a
/// 'treatment' variant could flip a `role_feature_overrides`-style toggle;
/// no concrete gate exists yet because zero experiments are actually
/// running in this phase (by design).
final experimentVariantProvider = Provider.family<String?, ExperimentModel>((
  ref,
  experiment,
) {
  final userId = ref.watch(currentUserProfileProvider).valueOrNull?.id;
  if (userId == null) return null;
  return ExperimentAssignmentService.assign(
    userId: userId,
    experimentKey: experiment.key,
    variantWeights: experiment.variantWeights,
  );
});

class AbTestingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> recordAssignment({
    required String experimentId,
    required String userId,
    required String variant,
  }) => ref
      .read(abTestingRepositoryProvider)
      .recordAssignment(
        experimentId: experimentId,
        userId: userId,
        variant: variant,
      );

  Future<void> recordEvent({
    required String experimentId,
    required String userId,
    required String eventKey,
  }) => ref
      .read(abTestingRepositoryProvider)
      .recordEvent(experimentId: experimentId, userId: userId, eventKey: eventKey);
}

final abTestingNotifierProvider =
    AsyncNotifierProvider<AbTestingNotifier, void>(AbTestingNotifier.new);
