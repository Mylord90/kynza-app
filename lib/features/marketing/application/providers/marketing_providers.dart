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
    try {
      await ref.read(marketingRepositoryProvider).addContact(contact);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> importFromBookings(String salonId) async {
    state = const AsyncLoading();
    try {
      final imported = await ref
          .read(marketingRepositoryProvider)
          .importFromBookings(salonId);
      state = const AsyncData(null);
      return imported;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await ref.read(marketingRepositoryProvider).deleteContact(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createPromotion(PromotionModel promotion) async {
    state = const AsyncLoading();
    try {
      await ref.read(marketingRepositoryProvider).createPromotion(promotion);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updatePromotion(PromotionModel promotion) async {
    state = const AsyncLoading();
    try {
      await ref.read(marketingRepositoryProvider).updatePromotion(promotion);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deactivatePromotion(String id) async {
    try {
      await ref.read(marketingRepositoryProvider).deactivatePromotion(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
