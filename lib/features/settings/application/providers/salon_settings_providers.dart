import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audit/audit_logger.dart';
import '../../../../core/models/salon_settings_model.dart';
import '../../data/repositories/salon_settings_repository_impl.dart';
import '../../domain/repositories/salon_settings_repository.dart';

final salonSettingsRepositoryProvider = Provider<SalonSettingsRepository>(
  (ref) => SalonSettingsRepositoryImpl(),
);

final salonSettingsProvider = FutureProvider.autoDispose
    .family<SalonSettingsModel, String>(
      (ref, salonId) =>
          ref.read(salonSettingsRepositoryProvider).getSettings(salonId),
    );

final salonSettingsNotifierProvider =
    AsyncNotifierProvider<SalonSettingsNotifier, void>(
      SalonSettingsNotifier.new,
    );

class SalonSettingsNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> updateField(
    String salonId,
    String key,
    dynamic oldValue,
    dynamic newValue,
  ) async {
    await ref.read(salonSettingsRepositoryProvider).updateSettings(salonId, {
      key: newValue,
    });
    ref.invalidate(salonSettingsProvider(salonId));
    AuditLogger.settingsChanged(salonId, key, oldValue, newValue);
  }
}
