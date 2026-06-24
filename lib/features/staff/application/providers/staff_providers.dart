import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepositoryImpl(),
);

/// The current user's own staff_profiles row (null if they're not staff
/// at any salon, or their invitation hasn't been linked yet).
final myStaffProfileProvider = FutureProvider<StaffProfileModel?>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) return null;
  final row = await SupabaseService.from('staff_profiles')
      .select()
      .eq('user_id', profile.id)
      .isFilter('deleted_at', null)
      .maybeSingle();
  if (row == null) return null;
  return StaffProfileModel.fromSupabase(row);
});

final salonStaffProvider =
    StreamProvider.family<List<StaffProfileModel>, String>((ref, salonId) {
      final client = ref.watch(supabaseClientProvider);
      return client
          .from('staff_profiles')
          .stream(primaryKey: ['id'])
          .eq('salon_id', salonId)
          .map(
            (rows) => rows
                .where((r) => r['deleted_at'] == null)
                .map(StaffProfileModel.fromSupabase)
                .toList(),
          );
    });

final staffNotifierProvider = AsyncNotifierProvider<StaffNotifier, void>(
  StaffNotifier.new,
);

class StaffNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> invite({
    required String salonId,
    required String displayName,
    required String phone,
    required String role,
    required String callerRole,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(staffRepositoryProvider)
          .inviteStaff(
            salonId: salonId,
            displayName: displayName,
            phone: phone,
            role: role,
            callerRole: callerRole,
          ),
    );
  }

  Future<void> updateStaff(StaffProfileModel staff) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(staffRepositoryProvider).updateStaff(staff),
    );
  }

  Future<void> toggleActive(String id, bool isActive) async {
    state = await AsyncValue.guard(
      () => ref.read(staffRepositoryProvider).toggleActive(id, isActive),
    );
  }

  Future<void> remove(String id) async {
    state = await AsyncValue.guard(
      () => ref.read(staffRepositoryProvider).removeStaff(id),
    );
  }

  Future<void> assignService(
    String staffId,
    String serviceId,
    String salonId,
  ) async {
    state = await AsyncValue.guard(
      () => ref
          .read(staffRepositoryProvider)
          .assignService(staffId, serviceId, salonId),
    );
  }

  Future<void> removeService(String staffId, String serviceId) async {
    state = await AsyncValue.guard(
      () => ref.read(staffRepositoryProvider).removeService(staffId, serviceId),
    );
  }
}
