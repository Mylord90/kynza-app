import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../data/repositories/commission_repository_impl.dart';
import '../../domain/repositories/commission_repository.dart';

final commissionRepositoryProvider = Provider<CommissionRepository>(
  (ref) => CommissionRepositoryImpl(),
);

final selectedCommissionMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final staffCommissionsProvider = FutureProvider.autoDispose
    .family<List<StaffCommissionModel>, String>((ref, staffId) {
      final month = ref.watch(selectedCommissionMonthProvider);
      return ref
          .read(commissionRepositoryProvider)
          .getStaffCommissions(staffId, month);
    });

final salonCommissionsProvider = FutureProvider.autoDispose
    .family<List<StaffCommissionModel>, String>((ref, salonId) {
      final month = ref.watch(selectedCommissionMonthProvider);
      return ref
          .read(commissionRepositoryProvider)
          .getSalonCommissions(salonId, month);
    });

final commissionSummaryProvider = FutureProvider.autoDispose
    .family<CommissionSummary, String>((ref, salonId) {
      final month = ref.watch(selectedCommissionMonthProvider);
      return ref
          .read(commissionRepositoryProvider)
          .getCommissionSummary(salonId, month);
    });

final commissionNotifierProvider =
    AsyncNotifierProvider<CommissionNotifier, void>(CommissionNotifier.new);

class CommissionNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> markPaid(String salonId, List<String> commissionIds) async {
    state = const AsyncLoading();
    try {
      await ref.read(commissionRepositoryProvider).markPaid(commissionIds);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonCommissionsProvider(salonId));
      ref.invalidate(commissionSummaryProvider(salonId));
    }
  }

  Future<void> updateRate(String staffId, String type, num value) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(commissionRepositoryProvider)
          .updateCommissionRate(staffId, type, value);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
