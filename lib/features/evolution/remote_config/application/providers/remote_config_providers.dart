import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/remote_config_entry_model.dart';
import '../../../../../core/models/remote_config_version_model.dart';
import '../../data/remote_config_cache.dart';
import '../../data/repositories/remote_config_repository_impl.dart';
import '../../domain/repositories/remote_config_repository.dart';

final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>(
  (ref) => RemoteConfigRepositoryImpl(),
);

/// Realtime-subscribed catalog — a value changed remotely (via the
/// update-remote-config Edge Function) reaches every connected app instance
/// through this stream without a redeploy. Mirrored into [RemoteConfigCache]
/// so [remoteConfigOfflineProvider] can serve the last-known snapshot.
final remoteConfigRealtimeProvider =
    StreamProvider<List<RemoteConfigEntryModel>>((ref) {
      final stream = ref.watch(remoteConfigRepositoryProvider).watchEntries();
      return stream.map((entries) {
        RemoteConfigCache.set(entries);
        return entries;
      });
    });

final remoteConfigOfflineProvider = Provider<List<RemoteConfigEntryModel>>((
  ref,
) {
  final live = ref.watch(remoteConfigRealtimeProvider);
  return live.when(
    data: (entries) => entries,
    loading: () => RemoteConfigCache.get() ?? const [],
    error: (_, __) => RemoteConfigCache.get() ?? const [],
  );
});

/// Offline-safe single-value read, e.g.
/// `ref.watch(remoteConfigValueProvider('default_commission_rate_percent'))`.
final remoteConfigValueProvider = Provider.family<dynamic, String>((
  ref,
  key,
) {
  final entries = ref.watch(remoteConfigOfflineProvider);
  for (final entry in entries) {
    if (entry.key == key) return entry.valueJson;
  }
  return RemoteConfigCache.getValue(key);
});

final remoteConfigVersionsProvider =
    FutureProvider.family<List<RemoteConfigVersionModel>, String>(
      (ref, entryId) =>
          ref.read(remoteConfigRepositoryProvider).getVersions(entryId),
    );

class RemoteConfigNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateEntry({
    required String key,
    required dynamic value,
    String? changeReason,
  }) async {
    await ref
        .read(remoteConfigRepositoryProvider)
        .updateEntry(key: key, value: value, changeReason: changeReason);
  }

  Future<void> rollback({
    required String key,
    required int versionNumber,
    required String entryId,
  }) async {
    await ref
        .read(remoteConfigRepositoryProvider)
        .rollback(key: key, versionNumber: versionNumber);
    ref.invalidate(remoteConfigVersionsProvider(entryId));
  }
}

final remoteConfigNotifierProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, void>(
      RemoteConfigNotifier.new,
    );
