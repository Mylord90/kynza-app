import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/audit_log_providers.dart';
import '../widgets/audit_log_tile.dart';

const _kPageSize = 20;

class _AuditFilter {
  const _AuditFilter(this.value, this.label);
  final String? value;
  final String label;
}

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = [
      _AuditFilter(null, l10n.auditLogFilterAll),
      _AuditFilter('booking', l10n.auditLogFilterBooking),
      _AuditFilter('payment', l10n.auditLogFilterPayment),
      _AuditFilter('staff', l10n.auditLogFilterStaff),
      _AuditFilter('settings', l10n.auditLogFilterSettings),
    ];
    final category = ref.watch(auditLogCategoryProvider);
    final limit = ref.watch(auditLogLimitProvider);
    final logsAsync = ref.watch(auditLogsProvider(widget.salonId));

    final filtered = logsAsync.valueOrNull?.where((log) {
      if (_dateRange == null) return true;
      final createdAt = log.createdAt;
      if (createdAt == null) return true;
      return !createdAt.isBefore(_dateRange!.start) &&
          !createdAt.isAfter(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.auditLogTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: l10n.dashboardAuditLogExportTooltip,
            onPressed: filtered == null || filtered.isEmpty
                ? null
                : () => ShareService.shareCsv(
                    CsvExporter.auditLogsToCsv(filtered),
                    'kynza-audit-${widget.salonId}.csv',
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = category == filter.value;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(auditLogCategoryProvider.notifier).state =
                            filter.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        filter.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: selected
                              ? AppColors.background
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    '${_dateRange!.start.day}/${_dateRange!.start.month} → '
                    '${_dateRange!.end.day}/${_dateRange!.end.month}',
                    style: AppTypography.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _dateRange = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: logsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 64),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: l10n.dashboardAuditLogLoadError,
                onRetry: () =>
                    ref.invalidate(auditLogsProvider(widget.salonId)),
              ),
              data: (_) {
                final logs = filtered ?? [];
                if (logs.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.history_outlined,
                    title: l10n.auditLogNoActivityTitle,
                    subtitle: l10n.auditLogNoActivitySubtitle,
                    ctaLabel: l10n.commonBack,
                    onCta: _noop,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(auditLogsProvider(widget.salonId)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: logs.length + (logs.length >= limit ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == logs.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Center(
                            child: TextButton(
                              onPressed: () =>
                                  ref
                                          .read(auditLogLimitProvider.notifier)
                                          .state +=
                                      _kPageSize,
                              child: Text(l10n.commonLoadMore),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AuditLogTile(log: logs[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
