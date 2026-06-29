import '../../../../core/models/salon_settings_model.dart';

abstract class SalonSettingsRepository {
  Future<SalonSettingsModel> getSettings(String salonId);

  Future<void> updateSettings(String salonId, Map<String, dynamic> patch);
}
