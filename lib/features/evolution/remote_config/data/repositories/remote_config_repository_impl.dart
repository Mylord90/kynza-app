import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/models/remote_config_entry_model.dart';
import '../../../../../core/models/remote_config_version_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/remote_config_repository.dart';

class RemoteConfigRepositoryImpl implements RemoteConfigRepository {
  @override
  Future<List<RemoteConfigEntryModel>> getEntries() async {
    final rows = await SupabaseService.from(
      'remote_config_entries',
    ).select().order('category').order('key');
    return rows.map((r) => RemoteConfigEntryModel.fromJson(r)).toList();
  }

  @override
  Stream<List<RemoteConfigEntryModel>> watchEntries() {
    return SupabaseService.client
        .from('remote_config_entries')
        .stream(primaryKey: ['id'])
        .order('key')
        .map(
          (rows) => rows
              .where((r) => r['deleted_at'] == null)
              .map(RemoteConfigEntryModel.fromJson)
              .toList(),
        );
  }

  @override
  Future<List<RemoteConfigVersionModel>> getVersions(String entryId) async {
    final rows = await SupabaseService.from('remote_config_versions')
        .select()
        .eq('entry_id', entryId)
        .order('version_number', ascending: false);
    return rows.map((r) => RemoteConfigVersionModel.fromJson(r)).toList();
  }

  @override
  Future<void> updateEntry({
    required String key,
    required dynamic value,
    String? changeReason,
  }) async {
    final res = await SupabaseService.client.functions.invoke(
      'update-remote-config',
      body: {'key': key, 'value': value, 'change_reason': changeReason},
    );
    final data = res.data is Map ? res.data as Map : null;
    if (res.status != 200 || data?['success'] != true) {
      throw AppException(
        (data?['message'] as String?) ??
            'Impossible de mettre à jour la configuration.',
      );
    }
  }

  @override
  Future<void> rollback({
    required String key,
    required int versionNumber,
  }) async {
    final res = await SupabaseService.client.functions.invoke(
      'rollback-remote-config',
      body: {'key': key, 'version_number': versionNumber},
    );
    final data = res.data is Map ? res.data as Map : null;
    if (res.status != 200 || data?['success'] != true) {
      throw AppException(
        (data?['message'] as String?) ??
            'Impossible de restaurer cette version.',
      );
    }
  }
}
