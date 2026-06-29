import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/salon_settings_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/salon_settings_repository.dart';

class SalonSettingsRepositoryImpl implements SalonSettingsRepository {
  @override
  Future<SalonSettingsModel> getSettings(String salonId) async {
    try {
      final row = await SupabaseService.from(
        'salon_settings',
      ).select().eq('salon_id', salonId).single();
      return SalonSettingsModel.fromJson(row);
    } catch (_) {
      throw const AppException(
        'Impossible de charger les paramètres du salon.',
      );
    }
  }

  @override
  Future<void> updateSettings(
    String salonId,
    Map<String, dynamic> patch,
  ) async {
    try {
      await SupabaseService.from(
        'salon_settings',
      ).update(patch).eq('salon_id', salonId);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour les paramètres.');
    }
  }
}
