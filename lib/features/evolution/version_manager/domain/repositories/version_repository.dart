import '../../../../../core/models/app_version_check_model.dart';

abstract class VersionRepository {
  Future<AppVersionCheckModel?> checkVersion();
}
