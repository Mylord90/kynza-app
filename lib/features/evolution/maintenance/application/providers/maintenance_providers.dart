import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/maintenance_window_model.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepositoryImpl(),
);

// Non-autoDispose: persists so the router can always read its cached state.
// Invalidated by MaintenanceScreen's periodic timer (every 30 s) so the
// router redirect fires again when maintenance ends.
final maintenanceStatusProvider = FutureProvider<MaintenanceWindowModel?>((
  ref,
) {
  return ref.read(maintenanceRepositoryProvider).checkMaintenance();
});
