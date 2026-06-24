import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/availability_exception_model.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../core/models/staff_break_model.dart';
import '../../../../core/models/staff_working_hour_model.dart';
import '../../../../core/services/availability_service.dart';
import '../../data/repositories/availability_repository_impl.dart';
import '../../domain/repositories/availability_repository.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepositoryImpl(),
);

final availabilityServiceProvider = Provider<AvailabilityService>(
  (ref) => AvailabilityService(),
);

final salonOverridesProvider =
    FutureProvider.family<List<AvailabilityOverrideModel>, String>(
      (ref, salonId) =>
          ref.read(availabilityRepositoryProvider).getOverrides(salonId),
    );

final staffWorkingHoursProvider =
    FutureProvider.family<List<StaffWorkingHourModel>, (String, String)>(
      (ref, params) => ref
          .read(availabilityRepositoryProvider)
          .getStaffWorkingHours(params.$1, params.$2),
    );

final staffBreaksProvider =
    FutureProvider.family<List<StaffBreakModel>, String>(
      (ref, staffId) =>
          ref.read(availabilityRepositoryProvider).getBreaks(staffId),
    );

final salonExceptionsProvider =
    FutureProvider.family<List<AvailabilityExceptionModel>, String>(
      (ref, salonId) =>
          ref.read(availabilityRepositoryProvider).getExceptions(salonId),
    );

final publicHolidaysProvider =
    FutureProvider.family<List<AvailabilityExceptionModel>, String>(
      (ref, salonId) =>
          ref.read(availabilityRepositoryProvider).getPublicHolidays(salonId),
    );

final availabilityNotifierProvider =
    AsyncNotifierProvider<AvailabilityNotifier, void>(AvailabilityNotifier.new);

class AvailabilityNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(AvailabilityOverrideModel override) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).upsertOverride(override),
    );
    ref.invalidate(salonOverridesProvider(override.salonId));
  }

  Future<void> delete(String id, String salonId) async {
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).deleteOverride(id),
    );
    ref.invalidate(salonOverridesProvider(salonId));
  }

  Future<void> saveStaffHours(
    String staffId,
    String salonId,
    List<StaffWorkingHourModel> hours,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(availabilityRepositoryProvider)
          .updateStaffWorkingHours(staffId, salonId, hours),
    );
    ref.invalidate(staffWorkingHoursProvider((staffId, salonId)));
  }

  Future<void> useSalonHours(String staffId, String salonId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(availabilityRepositoryProvider)
          .clearStaffWorkingHours(staffId),
    );
    ref.invalidate(staffWorkingHoursProvider((staffId, salonId)));
  }

  Future<void> saveBreak(StaffBreakModel draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).addBreak(draft),
    );
    ref.invalidate(staffBreaksProvider(draft.staffId));
  }

  Future<void> deleteBreak(String id, String staffId) async {
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).removeBreak(id),
    );
    ref.invalidate(staffBreaksProvider(staffId));
  }

  Future<void> saveException(AvailabilityExceptionModel draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).addException(draft),
    );
    ref.invalidate(salonExceptionsProvider(draft.salonId));
  }

  Future<void> deleteException(String id, String salonId) async {
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).removeException(id),
    );
    ref.invalidate(salonExceptionsProvider(salonId));
  }
}
