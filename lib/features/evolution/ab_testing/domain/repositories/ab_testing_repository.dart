import '../../../../../core/models/experiment_model.dart';

abstract class AbTestingRepository {
  Future<List<ExperimentModel>> getExperiments();

  /// Persists a computed assignment so server-side reporting can later
  /// cross-reference which variant a user landed in — the assignment
  /// itself is already known client-side (deterministic, offline-capable)
  /// before this call ever happens; this is a record, not a request.
  Future<void> recordAssignment({
    required String experimentId,
    required String userId,
    required String variant,
  });

  Future<void> recordEvent({
    required String experimentId,
    required String userId,
    required String eventKey,
  });
}
