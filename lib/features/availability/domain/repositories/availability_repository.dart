import '../../../../core/models/availability_override_model.dart';

abstract class AvailabilityRepository {
  Future<List<AvailabilityOverrideModel>> getOverrides(
    String salonId, {
    String? staffId,
  });
  Future<AvailabilityOverrideModel> upsertOverride(
    AvailabilityOverrideModel override,
  );
  Future<void> deleteOverride(String id);
}
