import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/models/billing/subscription_plan_model.dart';

abstract class BillingRepository {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<InvoiceModel> requestUpgrade(String planKey);
  Future<List<InvoiceModel>> getInvoices(String salonId);
  Future<InvoiceModel> markPaid(String invoiceId);
  Future<void> downgrade(String salonId, String planKey);
}
