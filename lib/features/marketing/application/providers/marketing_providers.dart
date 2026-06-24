import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/marketing/client_contact_model.dart';
import '../../../../core/models/marketing/promotion_model.dart';
import '../../data/repositories/marketing_repository_impl.dart';
import '../../domain/repositories/marketing_repository.dart';

final marketingRepositoryProvider = Provider<MarketingRepository>(
  (ref) => MarketingRepositoryImpl(),
);

final clientContactsProvider = StreamProvider.autoDispose
    .family<List<ClientContactModel>, String>(
      (ref, salonId) =>
          ref.watch(marketingRepositoryProvider).getContacts(salonId),
    );

final promotionsProvider = StreamProvider.autoDispose
    .family<List<PromotionModel>, String>(
      (ref, salonId) =>
          ref.watch(marketingRepositoryProvider).getPromotions(salonId),
    );

final salonReferralTokenProvider = FutureProvider.autoDispose
    .family<String, (String salonId, String ownerId)>(
      (ref, params) => ref
          .watch(marketingRepositoryProvider)
          .getOrCreateSalonReferralToken(params.$1, params.$2),
    );

final marketingNotifierProvider =
    AsyncNotifierProvider<MarketingNotifier, void>(MarketingNotifier.new);

class MarketingNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> addContact(ClientContactModel contact) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(marketingRepositoryProvider).addContact(contact),
    );
  }

  Future<int?> importFromBookings(String salonId) async {
    state = const AsyncLoading();
    var imported = 0;
    state = await AsyncValue.guard(() async {
      imported = await ref
          .read(marketingRepositoryProvider)
          .importFromBookings(salonId);
    });
    return state.hasError ? null : imported;
  }

  Future<void> deleteContact(String id) async {
    state = await AsyncValue.guard(
      () => ref.read(marketingRepositoryProvider).deleteContact(id),
    );
  }

  Future<void> createPromotion(PromotionModel promotion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(marketingRepositoryProvider).createPromotion(promotion),
    );
  }

  Future<void> updatePromotion(PromotionModel promotion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(marketingRepositoryProvider).updatePromotion(promotion),
    );
  }

  Future<void> deactivatePromotion(String id) async {
    state = await AsyncValue.guard(
      () => ref.read(marketingRepositoryProvider).deactivatePromotion(id),
    );
  }
}
