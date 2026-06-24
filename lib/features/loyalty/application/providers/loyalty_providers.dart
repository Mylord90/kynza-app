import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/loyalty/loyalty_card_model.dart';
import '../../../../core/models/loyalty/loyalty_program_model.dart';
import '../../../../core/models/loyalty/loyalty_stamp_log_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../data/repositories/loyalty_repository_impl.dart';
import '../../domain/repositories/loyalty_repository.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => LoyaltyRepositoryImpl(),
);

final loyaltyProgramProvider = FutureProvider.autoDispose
    .family<LoyaltyProgramModel?, String>(
      (ref, salonId) =>
          ref.watch(loyaltyRepositoryProvider).getLoyaltyProgram(salonId),
    );

final clientLoyaltyCardsProvider =
    StreamProvider.autoDispose<List<LoyaltyCardModel>>((ref) {
      final profile = ref.watch(currentUserProfileProvider).valueOrNull;
      if (profile == null) return const Stream.empty();
      return ref.watch(loyaltyRepositoryProvider).getClientCards(profile.id);
    });

final salonLoyaltyCardsProvider = FutureProvider.autoDispose
    .family<List<LoyaltyCardModel>, String>(
      (ref, salonId) =>
          ref.watch(loyaltyRepositoryProvider).getSalonCards(salonId),
    );

final stampLogsProvider = FutureProvider.autoDispose
    .family<List<LoyaltyStampLogModel>, String>(
      (ref, cardId) =>
          ref.watch(loyaltyRepositoryProvider).getStampLogs(cardId),
    );

final loyaltyNotifierProvider = AsyncNotifierProvider<LoyaltyNotifier, void>(
  LoyaltyNotifier.new,
);

class LoyaltyNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> setupProgram(LoyaltyProgramModel program) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loyaltyRepositoryProvider).upsertProgram(program),
    );
    ref.invalidate(loyaltyProgramProvider(program.salonId));
  }

  Future<void> addStamp(
    String salonId,
    String cardId, {
    String? bookingId,
  }) async {
    state = await AsyncValue.guard(
      () => ref
          .read(loyaltyRepositoryProvider)
          .addStamp(cardId, bookingId: bookingId),
    );
    ref.invalidate(salonLoyaltyCardsProvider(salonId));
  }

  Future<void> redeemReward(String salonId, String cardId) async {
    state = await AsyncValue.guard(
      () => ref.read(loyaltyRepositoryProvider).redeemReward(cardId),
    );
    ref.invalidate(salonLoyaltyCardsProvider(salonId));
  }
}
