import '../../../../core/models/journey/owner_journey_model.dart';

abstract class JourneyRepository {
  Future<OwnerJourneyModel?> getJourney(String salonId);
  Future<OwnerJourneyModel> markStep(String salonId, String stepKey);
  Stream<OwnerJourneyModel?> watchJourney(String salonId);
}
