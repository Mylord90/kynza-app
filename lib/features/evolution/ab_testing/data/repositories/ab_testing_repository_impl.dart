import '../../../../../core/models/experiment_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/ab_testing_repository.dart';

class AbTestingRepositoryImpl implements AbTestingRepository {
  @override
  Future<List<ExperimentModel>> getExperiments() async {
    final rows = await SupabaseService.from(
      'experiments',
    ).select().order('key');
    return rows.map((r) => ExperimentModel.fromJson(r)).toList();
  }

  @override
  Future<void> recordAssignment({
    required String experimentId,
    required String userId,
    required String variant,
  }) async {
    await SupabaseService.from('experiment_assignments').upsert({
      'experiment_id': experimentId,
      'user_id': userId,
      'variant': variant,
    }, onConflict: 'experiment_id,user_id');
  }

  @override
  Future<void> recordEvent({
    required String experimentId,
    required String userId,
    required String eventKey,
  }) async {
    await SupabaseService.from('experiment_events').insert({
      'experiment_id': experimentId,
      'user_id': userId,
      'event_key': eventKey,
    });
  }
}
