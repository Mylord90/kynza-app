import '../../../../../core/constants/app_version.dart';
import '../../../../../core/models/app_version_check_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/version_repository.dart';

class VersionRepositoryImpl implements VersionRepository {
  @override
  Future<AppVersionCheckModel?> checkVersion() async {
    // RPC requires auth.uid() — skip if not authenticated
    if (SupabaseService.auth.currentUser == null) return null;

    final rows = await SupabaseService.client.rpc(
      'check_app_version',
      params: {
        'p_platform': kAppPlatform,
        'p_version_code': kAppVersionCode,
      },
    ) as List<dynamic>;

    if (rows.isEmpty) return null;
    return AppVersionCheckModel.fromJson(
      rows.first as Map<String, dynamic>,
    );
  }
}