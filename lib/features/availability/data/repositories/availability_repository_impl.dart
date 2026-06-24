import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  static const _table = 'availability_overrides';

  @override
  Future<List<AvailabilityOverrideModel>> getOverrides(
    String salonId, {
    String? staffId,
  }) async {
    var query = SupabaseService.from(
      _table,
    ).select().eq('salon_id', salonId).isFilter('deleted_at', null);
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    final rows = await query.order('date');
    return rows.map(AvailabilityOverrideModel.fromSupabase).toList();
  }

  @override
  Future<AvailabilityOverrideModel> upsertOverride(
    AvailabilityOverrideModel override,
  ) async {
    try {
      final dateOnly = override.date.toIso8601String().substring(0, 10);
      final row = await SupabaseService.from(_table)
          .upsert({
            if (override.id != null) 'id': override.id,
            'salon_id': override.salonId,
            'staff_id': override.staffId,
            'date': dateOnly,
            'is_available': override.isAvailable,
            'opens_at': override.opensAt,
            'closes_at': override.closesAt,
            'reason': override.reason,
          })
          .select()
          .single();
      return AvailabilityOverrideModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible d'enregistrer cette exception.");
    }
  }

  @override
  Future<void> deleteOverride(String id) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer cette exception.');
    }
  }
}
