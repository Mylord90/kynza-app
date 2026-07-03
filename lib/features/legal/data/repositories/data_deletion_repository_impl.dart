import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/legal/data_deletion_request_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/data_deletion_repository.dart';

class DataDeletionRepositoryImpl implements DataDeletionRepository {
  static const _table = 'data_deletion_requests';

  @override
  Future<List<DataDeletionRequestModel>> getUserRequests(
    String userId,
  ) async {
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('requested_at', ascending: false);
    return rows.map(DataDeletionRequestModel.fromSupabase).toList();
  }

  @override
  Future<DataDeletionRequestModel> createRequest({
    required String userId,
    String? notes,
  }) async {
    try {
      final row = await SupabaseService.from(_table)
          .insert({'user_id': userId, if (notes != null) 'notes': notes})
          .select()
          .single();
      return DataDeletionRequestModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        'Impossible d\'envoyer votre demande de suppression de données.',
      );
    }
  }
}
