import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/backup_job_model.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepositoryImpl(),
);

final backupJobsProvider = FutureProvider.autoDispose
    .family<List<BackupJobModel>, String>(
      (ref, salonId) =>
          ref.read(backupRepositoryProvider).getBackupJobs(salonId),
    );

final backupNotifierProvider =
    AsyncNotifierProvider<BackupNotifier, void>(BackupNotifier.new);

class BackupNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<BackupJobModel> createBackup(String salonId) async {
    state = const AsyncLoading();
    try {
      final job = await ref.read(backupRepositoryProvider).createBackup();
      ref.invalidate(backupJobsProvider(salonId));
      state = const AsyncData(null);
      return job;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}