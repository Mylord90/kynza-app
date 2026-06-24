import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../core/services/availability_service.dart';
import '../../data/repositories/availability_repository_impl.dart';
import '../../domain/repositories/availability_repository.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepositoryImpl(),
);

final availabilityServiceProvider = Provider<AvailabilityService>(
  (ref) => AvailabilityService(),
);

final salonOverridesProvider =
    FutureProvider.family<List<AvailabilityOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(availabilityRepositoryProvider).getOverrides(salonId),
    );

final availabilityNotifierProvider =
    AsyncNotifierProvider<AvailabilityNotifier, void>(AvailabilityNotifier.new);

class AvailabilityNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(AvailabilityOverrideModel override) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).upsertOverride(override),
    );
    ref.invalidate(salonOverridesProvider(override.salonId));
  }

  Future<void> delete(String id, String salonId) async {
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).deleteOverride(id),
    );
    ref.invalidate(salonOverridesProvider(salonId));
  }
}
