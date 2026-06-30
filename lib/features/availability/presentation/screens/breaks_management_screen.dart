import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/staff_break_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/availability_providers.dart';
import '../widgets/break_editor_widget.dart';

class BreaksManagementScreen extends ConsumerWidget {
  const BreaksManagementScreen({
    super.key,
    required this.staffId,
    required this.salonId,
    required this.staffName,
  });

  final String staffId;
  final String salonId;
  final String staffName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breaksAsync = ref.watch(staffBreaksProvider(staffId));
    final l10n = context.l10n;
    final dayLabels = [
      l10n.weekdayMonday,
      l10n.weekdayTuesday,
      l10n.weekdayWednesday,
      l10n.weekdayThursday,
      l10n.weekdayFriday,
      l10n.weekdaySaturday,
      l10n.weekdaySunday,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.availabilityBreaksTitle(staffName))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showKynzaBottomSheet(
          context,
          builder: (_) => BreakEditorWidget(
            staffId: staffId,
            salonId: salonId,
            onSave: (draft) async {
              try {
                await ref
                    .read(availabilityNotifierProvider.notifier)
                    .saveBreak(draft);
              } catch (e) {
                if (context.mounted) {
                  showKynzaToast(
                    context,
                    message: e is AppException
                        ? e.message
                        : l10n.availabilitySaveFailed,
                    level: ToastLevel.error,
                  );
                }
              }
            },
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: breaksAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: KynzaSkeleton(height: 64),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: l10n.availabilityBreaksLoadError,
          onRetry: () => ref.invalidate(staffBreaksProvider(staffId)),
        ),
        data: (breaks) {
          if (breaks.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.free_breakfast_outlined,
              title: l10n.availabilityNoBreaksTitle,
              subtitle: l10n.availabilityNoBreaksSubtitle(staffName),
              ctaLabel: l10n.availabilityAddBreakCta,
              onCta: () => showKynzaBottomSheet(
                context,
                builder: (_) => BreakEditorWidget(
                  staffId: staffId,
                  salonId: salonId,
                  onSave: (draft) async {
                    try {
                      await ref
                          .read(availabilityNotifierProvider.notifier)
                          .saveBreak(draft);
                    } catch (e) {
                      if (context.mounted) {
                        showKynzaToast(
                          context,
                          message: e is AppException
                              ? e.message
                              : l10n.availabilitySaveFailed,
                          level: ToastLevel.error,
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: breaks.length,
            itemBuilder: (context, index) {
              final b = breaks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Dismissible(
                  key: ValueKey(b.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
                  onDismissed: (_) async {
                    try {
                      await ref
                          .read(availabilityNotifierProvider.notifier)
                          .deleteBreak(b.id!, staffId);
                    } catch (e) {
                      if (context.mounted) {
                        showKynzaToast(
                          context,
                          message: e is AppException
                              ? e.message
                              : l10n.availabilityDeleteFailed,
                          level: ToastLevel.error,
                        );
                      }
                    }
                  },
                  child: KynzaCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Text(
                            dayLabels[b.dayOfWeek],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.label, style: AppTypography.h3),
                              Text(
                                b.formattedRange,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
