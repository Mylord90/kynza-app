import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepositoryImpl(),
);

/// Realtime feed of a salon's services — debounced 300ms per
/// kynza-supabase-backend.md §7 to absorb burst inserts/updates.
final salonServicesProvider = StreamProvider.family<List<ServiceModel>, String>(
  (ref, salonId) {
    final client = ref.watch(supabaseClientProvider);
    return client
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(ServiceModel.fromSupabase)
                  .toList()
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
        );
  },
);

final serviceNotifierProvider = AsyncNotifierProvider<ServiceNotifier, void>(
  ServiceNotifier.new,
);

class ServiceNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> create(ServiceModel service) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).create(service),
    );
  }

  Future<void> updateService(ServiceModel service) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).update(service),
    );
  }

  Future<void> softDelete(String id) async {
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).softDelete(id),
    );
  }

  Future<void> toggleActive(String id, bool isActive) async {
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).toggleActive(id, isActive),
    );
  }

  Future<void> reorder(String salonId, List<String> orderedIds) async {
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).reorder(salonId, orderedIds),
    );
  }
}
