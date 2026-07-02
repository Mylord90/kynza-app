import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/proxipay/proxipay_session_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/proxipay_repository.dart';

class ProxiPayRepositoryImpl implements ProxiPayRepository {
  static const _sessionsTable = 'proxipay_sessions';

  @override
  Future<ProxiPaySessionModel> createSession(String bookingId) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'proxipay-create-session',
        body: {'bookingId': bookingId},
      );
      if (res.status != 200) throw const AppException('session_create_failed');
      final data = res.data as Map<String, dynamic>;
      final session = await getSession(data['sessionId'] as String);
      if (session == null) throw const AppException('session_create_failed');
      return session;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Impossible de générer le QR de paiement.');
    }
  }

  @override
  Future<ProxiPaySessionModel?> getSession(String sessionId) async {
    final row = await SupabaseService.from(
      _sessionsTable,
    ).select().eq('id', sessionId).maybeSingle();
    return row == null ? null : ProxiPaySessionModel.fromSupabase(row);
  }

  @override
  Future<void> confirmSession({
    required String sessionId,
    required String method,
    required String phone,
  }) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'proxipay-confirm',
        body: {'sessionId': sessionId, 'method': method, 'phone': phone},
      );
      if (res.status != 200) {
        final data = res.data is Map ? res.data as Map : null;
        throw AppException(data?['error'] as String? ?? 'confirm_failed');
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Impossible de confirmer le paiement.');
    }
  }

  @override
  Stream<ProxiPaySessionModel?> watchSession(String sessionId) {
    return SupabaseService.client
        .from(_sessionsTable)
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map(
          (rows) => rows.isEmpty
              ? null
              : ProxiPaySessionModel.fromSupabase(rows.first),
        );
  }
}
