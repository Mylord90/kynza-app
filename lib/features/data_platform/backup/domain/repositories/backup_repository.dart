import '../../../../../core/models/backup_job_model.dart';

abstract class BackupRepository {
  Future<List<BackupJobModel>> getBackupJobs(String salonId);
  Future<BackupJobModel> createBackup();
}