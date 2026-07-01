import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/analytics/cohort_retention_model.dart';

const _offsets = [0, 1, 2, 3];

/// Native [Table] — header = month offsets (M0..M3), rows = monthly
/// client cohorts, cell color gradients green→red by retentionPct.
class KynzaCohortTable extends StatelessWidget {
  const KynzaCohortTable({super.key, required this.rows});

  final List<CohortRetentionModel> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        context.l10n.dashboardNoCohortData,
        style: AppTypography.bodySmall,
      );
    }

    final months = rows.map((r) => r.cohortMonth).toSet().toList()..sort();
    final byKey = {for (final r in rows) (r.cohortMonth, r.monthOffset): r};

    return Table(
      border: const TableBorder.symmetric(
        inside: BorderSide(color: AppColors.border),
      ),
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                context.l10n.dashboardCohortHeader,
                style: AppTypography.bodySmall,
              ),
            ),
            for (final offset in _offsets)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'M$offset',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        for (final month in months)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  DateFormat('MMM yyyy', 'fr_FR').format(month),
                  style: AppTypography.bodySmall,
                ),
              ),
              for (final offset in _offsets)
                _CohortCell(model: byKey[(month, offset)]),
            ],
          ),
      ],
    );
  }
}

class _CohortCell extends StatelessWidget {
  const _CohortCell({required this.model});

  final CohortRetentionModel? model;

  @override
  Widget build(BuildContext context) {
    final cell = model;
    if (cell == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Text(
          '—',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    final pct = cell.retentionPct;
    final color = Color.lerp(AppColors.error, AppColors.success, pct)!;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${(pct * 100).round()}%',
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
