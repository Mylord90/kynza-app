import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/staff_commission_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/commission_repository.dart';

DateTime _monthStart(DateTime month) =>
    DateTime.utc(month.year, month.month, 1);
DateTime _monthEnd(DateTime month) => DateTime.utc(
  month.month == 12 ? month.year + 1 : month.year,
  month.month == 12 ? 1 : month.month + 1,
  1,
);

class CommissionRepositoryImpl implements CommissionRepository {
  static const _table = 'staff_commissions';

  @override
  Future<List<StaffCommissionModel>> getStaffCommissions(
    String staffId,
    DateTime month,
  ) async {
    try {
      final rows = await SupabaseService.from(_table)
          .select()
          .eq('staff_id', staffId)
          .isFilter('deleted_at', null)
          .gte('created_at', _monthStart(month).toIso8601String())
          .lt('created_at', _monthEnd(month).toIso8601String())
          .order('created_at', ascending: false);
      return rows.map(StaffCommissionModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger vos commissions.');
    }
  }

  @override
  Future<List<StaffCommissionModel>> getSalonCommissions(
    String salonId,
    DateTime month,
  ) async {
    try {
      final rows = await SupabaseService.from(_table)
          .select()
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .gte('created_at', _monthStart(month).toIso8601String())
          .lt('created_at', _monthEnd(month).toIso8601String())
          .order('created_at', ascending: false);
      return rows.map(StaffCommissionModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les commissions.');
    }
  }

  @override
  Future<void> markPaid(List<String> commissionIds) async {
    if (commissionIds.isEmpty) return;
    try {
      await SupabaseService.from(_table)
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', commissionIds);
    } catch (_) {
      throw const AppException('Impossible de marquer ces commissions payées.');
    }
  }

  @override
  Future<CommissionSummary> getCommissionSummary(
    String salonId,
    DateTime month,
  ) async {
    final rows = await getSalonCommissions(salonId, month);
    var paid = 0;
    var pending = 0;
    for (final row in rows) {
      if (row.isPaid) {
        paid += row.amountBif;
      } else {
        pending += row.amountBif;
      }
    }
    return CommissionSummary(
      earnedBif: paid + pending,
      paidBif: paid,
      pendingBif: pending,
    );
  }

  @override
  Future<void> updateCommissionRate(
    String staffId,
    String type,
    num value,
  ) async {
    try {
      await SupabaseService.from('staff_profiles')
          .update({'commission_type': type, 'commission_rate': value})
          .eq('id', staffId);
    } catch (_) {
      throw const AppException(
        'Impossible de mettre à jour le taux de commission.',
      );
    }
  }
}
