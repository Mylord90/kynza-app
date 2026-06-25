import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/journey/owner_journey_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/journey_repository_impl.dart';
import '../../domain/repositories/journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => JourneyRepositoryImpl(),
);

final ownerJourneyProvider = StreamProvider.autoDispose
    .family<OwnerJourneyModel?, String>((ref, salonId) async* {
      final repo = ref.watch(journeyRepositoryProvider);
      // watchJourney() depends on owner_journey_progress being part of the
      // supabase_realtime publication. Fetch once up front so the card
      // still renders even if Realtime is ever unavailable, then follow
      // live updates.
      yield await repo.getJourney(salonId);
      yield* repo.watchJourney(salonId);
    });

final journeyNotifierProvider = AsyncNotifierProvider<JourneyNotifier, void>(
  JourneyNotifier.new,
);

class JourneyNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> markStep(String salonId, String stepKey) async {
    try {
      await ref.read(journeyRepositoryProvider).markStep(salonId, stepKey);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Persists in Hive once dismissed at 100% — see SessionService.
class JourneyDismissedNotifier extends FamilyNotifier<bool, String> {
  @override
  bool build(String salonId) =>
      ref.watch(sessionServiceProvider).isJourneyCardDismissed(salonId);

  void dismiss(String salonId) {
    ref.read(sessionServiceProvider).dismissJourneyCard(salonId);
    state = true;
  }
}

final journeyDismissedProvider =
    NotifierProvider.family<JourneyDismissedNotifier, bool, String>(
      JourneyDismissedNotifier.new,
    );
