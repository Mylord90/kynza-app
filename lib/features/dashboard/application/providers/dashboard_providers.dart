import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/date_range.dart';
import '../../../../core/models/analytics/dashboard_summary_model.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepositoryImpl(),
);

final selectedPeriodProvider = StateProvider<DateRange>(
  (ref) => DateRange.today,
);

/// Re-fetches every 5 minutes while watched (kynza-supabase-backend.md —
/// live data TTL) in addition to refetching whenever the period changes.
final dashboardSummaryProvider = FutureProvider.autoDispose
    .family<DashboardSummary, String>((ref, salonId) {
      final timer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      final range = ref.watch(selectedPeriodProvider);
      return ref.read(analyticsRepositoryProvider).getSummary(salonId, range);
    });

final topServicesProvider = FutureProvider.autoDispose
    .family<List<TopServiceModel>, String>((ref, salonId) {
      final now = DateTime.now();
      return ref
          .read(analyticsRepositoryProvider)
          .getTopServices(salonId, DateTime(now.year, now.month));
    });

final topStaffProvider = FutureProvider.autoDispose
    .family<List<TopStaffModel>, String>((ref, salonId) {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );
      return ref
          .read(analyticsRepositoryProvider)
          .getTopStaff(salonId, weekStart);
    });
