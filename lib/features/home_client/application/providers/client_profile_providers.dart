import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/offline_sync_providers.dart';
import '../../../../core/services/offline_sync_coordinator.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/client_profile_repository_impl.dart';
import '../../domain/repositories/client_profile_repository.dart';

final clientProfileRepositoryProvider = Provider<ClientProfileRepository>(
  (ref) => ClientProfileRepositoryImpl(),
);

final clientProfileNotifierProvider =
    AsyncNotifierProvider<ClientProfileNotifier, void>(
      ClientProfileNotifier.new,
    );

class ClientProfileNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Offline-first: writes directly when online; when offline, queues via
  /// the generic mutation outbox with `dedupeKey: userId` — a "last write
  /// wins" queue, so editing your profile twice while offline only ever
  /// replays the most recent edit, never both. Safe to replay unconditionally
  /// on reconnect: an UPDATE is idempotent by nature, no duplicate-check
  /// needed (contrast with review creation's `canReview()` guard). Both the
  /// online path here and `OfflineSyncCoordinator`'s replay path go through
  /// the same `ClientProfileRepository`, so there's exactly one place that
  /// actually performs the write.
  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? false;
      if (!isOnline) {
        await ref.read(mutationOutboxServiceProvider).enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {
            'userId': userId,
            'fullName': fullName,
            'phone': phone,
            'email': email,
          },
          dedupeKey: userId,
        );
      } else {
        await ref.read(clientProfileRepositoryProvider).updateProfile(
          userId: userId,
          fullName: fullName,
          phone: phone,
          email: email,
        );
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(currentUserProfileProvider);
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String ext) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final url = await StorageService.uploadUserAvatar(userId, bytes, ext);
      await SupabaseService.from(
        'users',
      ).update({'avatar_url': url}).eq('id', userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(currentUserProfileProvider);
    }
  }
}
