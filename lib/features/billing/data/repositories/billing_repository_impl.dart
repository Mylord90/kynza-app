import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/models/billing/subscription_plan_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final rows = await SupabaseService.from(
        'subscription_plans',
      ).select().eq('is_active', true).order('price_bif');
      return rows.map(SubscriptionPlanModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException("Impossible de charger les plans d'abonnement.");
    }
  }

  @override
  Future<InvoiceModel> requestUpgrade(String planKey) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-manual-invoice',
        body: {'plan_key': planKey},
      );
      final data = res.data is Map ? res.data as Map : null;
      if (res.status != 200 || data?['success'] != true) {
        throw const AppException(
          "Impossible de créer la demande de mise à niveau.",
        );
      }
      return InvoiceModel.fromSupabase(
        data!['invoice'] as Map<String, dynamic>,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        "Impossible de créer la demande de mise à niveau.",
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoices(String salonId) async {
    try {
      final rows = await SupabaseService.from('invoices')
          .select()
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return rows.map(InvoiceModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les factures.');
    }
  }

  @override
  Future<InvoiceModel> markPaid(String invoiceId) async {
    try {
      final row = await SupabaseService.client.rpc(
        'mark_invoice_paid',
        params: {'p_invoice_id': invoiceId},
      );
      return InvoiceModel.fromSupabase(row as Map<String, dynamic>);
    } catch (_) {
      throw const AppException(
        'Impossible de marquer cette facture comme payée.',
      );
    }
  }

  @override
  Future<void> downgrade(String salonId, String planKey) async {
    try {
      await SupabaseService.from('salons')
          .update({
            'plan': planKey,
            'plan_status': 'active',
            'plan_started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', salonId);
    } catch (_) {
      throw const AppException('Impossible de changer de plan.');
    }
  }
}
