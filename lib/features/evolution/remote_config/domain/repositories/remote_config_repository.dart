import '../../../../../core/models/remote_config_entry_model.dart';
import '../../../../../core/models/remote_config_version_model.dart';

abstract class RemoteConfigRepository {
  Future<List<RemoteConfigEntryModel>> getEntries();

  /// Realtime-subscribed catalog — a config value changed remotely reaches
  /// a running app instance without a redeploy.
  Stream<List<RemoteConfigEntryModel>> watchEntries();

  Future<List<RemoteConfigVersionModel>> getVersions(String entryId);

  /// Goes through the `update-remote-config` Edge Function, which validates
  /// [value] against the entry's value_type + category refinement before
  /// writing anything — never a direct table write.
  Future<void> updateEntry({
    required String key,
    required dynamic value,
    String? changeReason,
  });

  /// Goes through the `rollback-remote-config` Edge Function.
  Future<void> rollback({required String key, required int versionNumber});
}
