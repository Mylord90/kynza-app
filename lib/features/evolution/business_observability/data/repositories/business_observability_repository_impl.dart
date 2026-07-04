import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/business_observability_repository.dart';

class BusinessObservabilityRepositoryImpl
    implements BusinessObservabilityRepository {
  Future<List<Map<String, dynamic>>> _callRpc(String function) async {
    final result = await SupabaseService.client.rpc(function);
    if (result is List) {
      return result.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    }
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getRevenue() => _callRpc('get_bi_revenue');

  @override
  Future<List<Map<String, dynamic>>> getSalons() => _callRpc('get_bi_salons');

  @override
  Future<List<Map<String, dynamic>>> getStaff() => _callRpc('get_bi_staff');

  @override
  Future<List<Map<String, dynamic>>> getClients() => _callRpc('get_bi_clients');

  @override
  Future<List<Map<String, dynamic>>> getSubscriptions() =>
      _callRpc('get_bi_subscriptions');

  @override
  Future<List<Map<String, dynamic>>> getCommissions() =>
      _callRpc('get_bi_commissions');

  @override
  Future<List<Map<String, dynamic>>> getBookings() => _callRpc('get_bi_bookings');

  @override
  Future<List<Map<String, dynamic>>> getPayments() => _callRpc('get_bi_payments');

  @override
  Future<List<Map<String, dynamic>>> getLoyalty() => _callRpc('get_bi_loyalty');

  @override
  Future<List<Map<String, dynamic>>> getReferrals() =>
      _callRpc('get_bi_referrals');

  @override
  Future<List<Map<String, dynamic>>> getActivation() =>
      _callRpc('get_bi_activation');

  @override
  Future<List<Map<String, dynamic>>> getLtv() => _callRpc('get_bi_ltv');

  @override
  Future<List<Map<String, dynamic>>> getConversion() =>
      _callRpc('get_bi_conversion');
}
