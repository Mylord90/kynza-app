import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/business_observability_repository_impl.dart';
import '../../domain/repositories/business_observability_repository.dart';

final businessObservabilityRepositoryProvider =
    Provider<BusinessObservabilityRepository>(
      (ref) => BusinessObservabilityRepositoryImpl(),
    );

/// No dashboard screen watches these in this pass (Track B) — they exist so
/// building the dashboard UI later is wiring, not data-modeling.
final biRevenueProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getRevenue(),
);
final biSalonsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getSalons(),
);
final biStaffProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getStaff(),
);
final biClientsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getClients(),
);
final biSubscriptionsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getSubscriptions(),
);
final biCommissionsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getCommissions(),
);
final biBookingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getBookings(),
);
final biPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getPayments(),
);
final biLoyaltyProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getLoyalty(),
);
final biReferralsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getReferrals(),
);
final biActivationProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getActivation(),
);
final biLtvProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getLtv(),
);
final biConversionProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(businessObservabilityRepositoryProvider).getConversion(),
);
