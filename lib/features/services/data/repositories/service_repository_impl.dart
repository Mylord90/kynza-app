import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  static const _table = 'services';

  @override
  Future<List<ServiceModel>> getAll(String salonId) async {
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('salon_id', salonId)
        .isFilter('deleted_at', null)
        .order('display_order');
    return rows.map(ServiceModel.fromSupabase).toList();
  }

  @override
  Future<ServiceModel> create(ServiceModel service) async {
    try {
      final row = await SupabaseService.from(_table)
          .insert({
            'salon_id': service.salonId,
            'name': service.name,
            'description': service.description,
            'category': service.category,
            'duration_min': service.durationMin,
            'buffer_min': service.bufferMin,
            'price_bif': service.priceBif,
            'image_url': service.imageUrl,
          })
          .select()
          .single();
      return ServiceModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de créer ce service. Réessayez.');
    }
  }

  @override
  Future<ServiceModel> update(ServiceModel service) async {
    try {
      final row = await SupabaseService.from(_table)
          .update({
            'name': service.name,
            'description': service.description,
            'category': service.category,
            'duration_min': service.durationMin,
            'buffer_min': service.bufferMin,
            'price_bif': service.priceBif,
            'image_url': service.imageUrl,
          })
          .eq('id', service.id!)
          .select()
          .single();
      return ServiceModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour ce service.');
    }
  }

  @override
  Future<void> softDelete(String id) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce service.');
    }
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'is_active': isActive}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour ce service.');
    }
  }

  @override
  Future<void> reorder(String salonId, List<String> orderedIds) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await SupabaseService.from(_table)
            .update({'display_order': i})
            .eq('id', orderedIds[i])
            .eq('salon_id', salonId);
      }
    } catch (_) {
      throw const AppException('Impossible de réorganiser les services.');
    }
  }
}
