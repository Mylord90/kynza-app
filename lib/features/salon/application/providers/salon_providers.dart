import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/salon_media_model.dart';
import '../../../../core/models/working_hour_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../data/repositories/salon_repository_impl.dart';
import '../../domain/repositories/salon_repository.dart';

final salonRepositoryProvider = Provider<SalonRepository>(
  (ref) => SalonRepositoryImpl(),
);

final discoverSalonsProvider = FutureProvider<List<SalonFullModel>>(
  (ref) => ref.read(salonRepositoryProvider).getDiscoverSalons(),
);

final salonIdsByCategoryProvider = FutureProvider.family<Set<String>, String>(
  (ref, category) =>
      ref.read(salonRepositoryProvider).getSalonIdsByCategory(category),
);

final salonByIdProvider = FutureProvider.family<SalonFullModel?, String>(
  (ref, salonId) => ref.read(salonRepositoryProvider).getSalon(salonId),
);

final ownerSalonProvider = FutureProvider<SalonFullModel?>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) return null;
  return ref.read(salonRepositoryProvider).getOwnerSalon(profile.id);
});

final salonNotifierProvider =
    AsyncNotifierProvider<SalonNotifier, SalonFullModel?>(SalonNotifier.new);

class SalonNotifier extends AsyncNotifier<SalonFullModel?> {
  @override
  Future<SalonFullModel?> build() async {
    final profile = await ref.watch(currentUserProfileProvider.future);
    if (profile == null) return null;
    return ref.read(salonRepositoryProvider).getOwnerSalon(profile.id);
  }

  Future<SalonFullModel> create(SalonFullModel draft) async {
    state = const AsyncLoading();
    try {
      final created = await ref
          .read(salonRepositoryProvider)
          .createSalon(draft);
      ref.invalidate(currentUserProfileProvider);
      state = AsyncData(created);
      return created;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateSalon(SalonFullModel salon) async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final updated = await ref
          .read(salonRepositoryProvider)
          .updateSalon(salon);
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      throw e is AppException
          ? e
          : const AppException('Échec de la mise à jour.');
    }
  }

  Future<void> uploadLogo(Uint8List bytes, String ext) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    final url = await ref
        .read(salonRepositoryProvider)
        .uploadLogo(salon.id, bytes, ext);
    state = AsyncData(salon.copyWith(logoUrl: url));
    await updateSalon(salon.copyWith(logoUrl: url));
  }

  Future<void> uploadCover(Uint8List bytes, String ext) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    final url = await ref
        .read(salonRepositoryProvider)
        .uploadCover(salon.id, bytes, ext);
    state = AsyncData(salon.copyWith(coverUrl: url));
    await updateSalon(salon.copyWith(coverUrl: url));
  }

  Future<void> uploadMedia(Uint8List bytes, String ext, MediaType type) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    final media = await ref
        .read(salonRepositoryProvider)
        .uploadMedia(salon.id, bytes, ext, type);
    state = AsyncData(salon.copyWith(media: [...salon.media, media]));
  }

  Future<void> deleteMedia(String mediaId) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    await ref.read(salonRepositoryProvider).deleteMedia(mediaId);
    state = AsyncData(
      salon.copyWith(media: salon.media.where((m) => m.id != mediaId).toList()),
    );
  }

  Future<void> reorderMedia(List<String> orderedIds) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    await ref.read(salonRepositoryProvider).reorderMedia(salon.id, orderedIds);
    final byId = {for (final m in salon.media) m.id: m};
    state = AsyncData(
      salon.copyWith(
        media: [
          for (var i = 0; i < orderedIds.length; i++)
            if (byId[orderedIds[i]] != null)
              byId[orderedIds[i]]!.copyWith(displayOrder: i),
        ],
      ),
    );
  }

  Future<void> updateWorkingHours(List<WorkingHourModel> hours) async {
    final salon = state.valueOrNull;
    if (salon == null) return;
    await ref.read(salonRepositoryProvider).updateWorkingHours(salon.id, hours);
    state = AsyncData(salon.copyWith(workingHours: hours));
  }
}
