import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing/invoice_model.dart';
import '../../../../core/models/billing/subscription_plan_model.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../domain/repositories/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepositoryImpl(),
);

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanModel>>(
      (ref) => ref.read(billingRepositoryProvider).getPlans(),
    );

final salonInvoicesProvider = FutureProvider.autoDispose
    .family<List<InvoiceModel>, String>(
      (ref, salonId) =>
          ref.read(billingRepositoryProvider).getInvoices(salonId),
    );

final billingNotifierProvider = AsyncNotifierProvider<BillingNotifier, void>(
  BillingNotifier.new,
);

class BillingNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<InvoiceModel> requestUpgrade(String planKey) async {
    state = const AsyncLoading();
    try {
      final invoice = await ref
          .read(billingRepositoryProvider)
          .requestUpgrade(planKey);
      state = const AsyncData(null);
      return invoice;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markPaid(String salonId, String invoiceId) async {
    state = const AsyncLoading();
    try {
      await ref.read(billingRepositoryProvider).markPaid(invoiceId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonInvoicesProvider(salonId));
    }
  }

  Future<void> downgrade(String salonId, String planKey) async {
    state = const AsyncLoading();
    try {
      await ref.read(billingRepositoryProvider).downgrade(salonId, planKey);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
