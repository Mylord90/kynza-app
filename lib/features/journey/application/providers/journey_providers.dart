import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/journey/owner_journey_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/journey_repository_impl.dart';
import '../../domain/repositories/journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => JourneyRepositoryImpl(),
);

final ownerJourneyProvider = StreamProvider.autoDispose
    .family<OwnerJourneyModel?, String>(
      (ref, salonId) =>
          ref.watch(journeyRepositoryProvider).watchJourney(salonId),
    );

final journeyNotifierProvider = AsyncNotifierProvider<JourneyNotifier, void>(
  JourneyNotifier.new,
);

class JourneyNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> markStep(String salonId, String stepKey) async {
    state = await AsyncValue.guard(
      () => ref.read(journeyRepositoryProvider).markStep(salonId, stepKey),
    );
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
