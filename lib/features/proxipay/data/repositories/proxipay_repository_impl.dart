import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/proxipay/proxipay_session_model.dart';
import '../../../../core/security/app_check_service.dart';
import '../../../../core/services/performance_monitoring_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/proxipay_repository.dart';

/// P2-10 (Master Inventory: zero repository-layer test files exist, no
/// DI/mocking seam for any repository wrapping `SupabaseService` directly)
/// — the injectable [client] parameter is the seam: production code never
/// passes it (defaults to the real `SupabaseService.client`, identical
/// behavior to before), tests inject a fake `SupabaseClient` instead.
class ProxiPayRepositoryImpl implements ProxiPayRepository {
  ProxiPayRepositoryImpl({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  static const _sessionsTable = 'proxipay_sessions';

  @override
  Future<ProxiPaySessionModel> createSession(String bookingId) async {
    try {
      final res = await _client.functions.invoke(
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
    final row = await _client
        .from(_sessionsTable)
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    return row == null ? null : ProxiPaySessionModel.fromSupabase(row);
  }

  @override
  Future<void> confirmSession({
    required String sessionId,
    required String method,
    required String phone,
  }) {
    return PerformanceMonitoringService.traceAsync(
      'proxipay_payment_confirmation',
      () async {
        try {
          final res = await _client.functions.invoke(
            'proxipay-confirm',
            body: {'sessionId': sessionId, 'method': method, 'phone': phone},
            headers: await AppCheckService.headers(),
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
      },
    );
  }

  @override
  Stream<ProxiPaySessionModel?> watchSession(String sessionId) {
    return _client
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
