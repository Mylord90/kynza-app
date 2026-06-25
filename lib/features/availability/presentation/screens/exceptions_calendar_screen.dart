import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/availability_providers.dart';
import '../widgets/exception_form_widget.dart';
import '../widgets/exception_list_tile.dart';

/// Sorted list of upcoming exceptions rather than a full month-grid
/// calendar — same data, fewer moving parts to ship and review. Public
/// holidays are shown read-only underneath (seeded server-side).
class ExceptionsCalendarScreen extends ConsumerWidget {
  const ExceptionsCalendarScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exceptionsAsync = ref.watch(salonExceptionsProvider(salonId));
    final holidaysAsync = ref.watch(publicHolidaysProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Jours exceptionnels')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showKynzaBottomSheet(
          context,
          builder: (_) => ExceptionFormWidget(
            salonId: salonId,
            onSave: (draft) async {
              try {
                await ref
                    .read(availabilityNotifierProvider.notifier)
                    .saveException(draft);
              } catch (e) {
                if (context.mounted) {
                  showKynzaToast(
                    context,
                    message: e is AppException
                        ? e.message
                        : "Échec de l'enregistrement.",
                    level: ToastLevel.error,
                  );
                }
              }
            },
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          exceptionsAsync.when(
            loading: () => const KynzaSkeleton(height: 200),
            error: (_, __) => KynzaErrorState(
              message: 'Impossible de charger les jours exceptionnels.',
              onRetry: () => ref.invalidate(salonExceptionsProvider(salonId)),
            ),
            data: (exceptions) {
              if (exceptions.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'Aucun jour exceptionnel',
                  subtitle: 'Ajoutez vos vacances ou fermetures spéciales.',
                  ctaLabel: 'Ajouter',
                  onCta: () => showKynzaBottomSheet(
                    context,
                    builder: (_) => ExceptionFormWidget(
                      salonId: salonId,
                      onSave: (draft) async {
                        try {
                          await ref
                              .read(availabilityNotifierProvider.notifier)
                              .saveException(draft);
                        } catch (e) {
                          if (context.mounted) {
                            showKynzaToast(
                              context,
                              message: e is AppException
                                  ? e.message
                                  : "Échec de l'enregistrement.",
                              level: ToastLevel.error,
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final exception in exceptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ExceptionListTile(
                        exception: exception,
                        onDelete: () async {
                          try {
                            await ref
                                .read(availabilityNotifierProvider.notifier)
                                .deleteException(exception.id!, salonId);
                          } catch (e) {
                            if (context.mounted) {
                              showKynzaToast(
                                context,
                                message: e is AppException
                                    ? e.message
                                    : 'Échec de la suppression.',
                                level: ToastLevel.error,
                              );
                            }
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Jours fériés', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          holidaysAsync.when(
            loading: () => const KynzaSkeleton(height: 100),
            error: (_, __) => const SizedBox.shrink(),
            data: (holidays) => holidays.isEmpty
                ? const Text(
                    'Aucun jour férié configuré.',
                    style: AppTypography.bodySmall,
                  )
                : Column(
                    children: [
                      for (final holiday in holidays)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: KynzaCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    holiday.label,
                                    style: AppTypography.body,
                                  ),
                                ),
                                Text(
                                  '${holiday.startDate.day}/${holiday.startDate.month}/${holiday.startDate.year}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
