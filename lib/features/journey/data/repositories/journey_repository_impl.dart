import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/journey/owner_journey_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/journey_repository.dart';

class JourneyRepositoryImpl implements JourneyRepository {
  static const _table = 'owner_journey_progress';

  static const _stepColumns = {
    'salon_info': 'step_salon_info_done',
    'first_service': 'step_first_service_done',
    'team': 'step_team_done',
    'hours': 'step_hours_done',
    'first_booking': 'step_first_booking_done',
  };

  @override
  Future<OwnerJourneyModel?> getJourney(String salonId) async {
    final row = await SupabaseService.from(
      _table,
    ).select().eq('salon_id', salonId).maybeSingle();
    return row == null ? null : OwnerJourneyModel.fromSupabase(row);
  }

  @override
  Future<OwnerJourneyModel> markStep(String salonId, String stepKey) async {
    final doneCol = _stepColumns[stepKey];
    if (doneCol == null) {
      throw const AppException('Étape de progression inconnue.');
    }

    final current = await getJourney(salonId);
    if (current != null && current.isStepDone(stepKey)) return current;

    try {
      final row = await SupabaseService.from(_table)
          .update({
            doneCol: true,
            '${doneCol}_at': DateTime.now().toIso8601String(),
          })
          .eq('salon_id', salonId)
          .select()
          .single();
      final journey = OwnerJourneyModel.fromSupabase(row);
      _notifyStepComplete(journey);
      return journey;
    } catch (_) {
      throw const AppException(
        'Impossible de mettre à jour votre progression.',
      );
    }
  }

  Future<void> _notifyStepComplete(OwnerJourneyModel journey) async {
    try {
      await SupabaseService.client.functions.invoke(
        'send-notification',
        body: {
          'userId': journey.ownerId,
          'event': 'journey_step_complete',
          'salonId': journey.salonId,
          'data': {'pct': '${journey.completionPct}'},
        },
      );
    } catch (_) {
      // Best-effort — never blocks the step from being marked done.
    }
  }

  @override
  Stream<OwnerJourneyModel?> watchJourney(String salonId) {
    return SupabaseService.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .map(
          (rows) =>
              rows.isEmpty ? null : OwnerJourneyModel.fromSupabase(rows.first),
        );
  }
}
