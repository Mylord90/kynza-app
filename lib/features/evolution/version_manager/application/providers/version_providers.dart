import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/app_version_check_model.dart';
import '../../data/repositories/version_repository_impl.dart';
import '../../domain/repositories/version_repository.dart';

final versionRepositoryProvider = Provider<VersionRepository>(
  (ref) => VersionRepositoryImpl(),
);

// Non-autoDispose: checked once on app start; the router reads this to
// block navigation when update_required is true.
// Invalidated by ForceUpdateScreen's "Vérifier à nouveau" button.
final appVersionCheckProvider =
    FutureProvider<AppVersionCheckModel?>((ref) {
  return ref.read(versionRepositoryProvider).checkVersion();
});