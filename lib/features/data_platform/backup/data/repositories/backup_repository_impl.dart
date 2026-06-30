import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/models/backup_job_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  @override
  Future<List<BackupJobModel>> getBackupJobs(String salonId) async {
    try {
      final rows = await SupabaseService.from('backup_jobs')
          .select()
          .eq('salon_id', salonId)
          .order('created_at', ascending: false)
          .limit(20);
      return rows.map(BackupJobModel.fromJson).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les sauvegardes.');
    }
  }

  @override
  Future<BackupJobModel> createBackup() async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-backup',
      );
      if (res.status != 200) {
        final body = res.data as Map<String, dynamic>?;
        final msg = body?['message'] as String?;
        if (res.status == 429) {
          throw AppException(
            msg ?? 'Un seul backup toutes les 6 heures est autorisé.',
          );
        }
        throw const AppException('La sauvegarde a échoué.');
      }
      final body = res.data as Map<String, dynamic>;
      // Re-fetch the full job row so we have all fields
      final rows = await SupabaseService.from('backup_jobs')
          .select()
          .eq('id', body['job_id'] as String)
          .single();
      return BackupJobModel.fromJson(rows);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('La sauvegarde a échoué.');
    }
  }
}