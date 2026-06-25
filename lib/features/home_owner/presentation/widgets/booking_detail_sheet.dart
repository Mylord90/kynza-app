import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/booking_status_chip.dart';

class BookingDetailSheet extends ConsumerWidget {
  const BookingDetailSheet({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingActionNotifierProvider.notifier);
    final canCancel = booking.canCancel;
    final gracePassed = DateTime.now().isAfter(
      booking.startTime.add(const Duration(minutes: 15)),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                DateFormat(
                  'EEEE d MMMM · HH:mm',
                  'fr_FR',
                ).format(booking.startTime),
                style: AppTypography.h2,
              ),
              const Spacer(),
              BookingStatusChip(booking: booking),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaAmountWidget(amountBif: booking.amountBif),
          if (booking.notes != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(booking.notes!, style: AppTypography.body),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (booking.status == BookingStatus.confirmed) ...[
            KynzaButton(
              label: 'Terminer + encaisser',
              onPressed: () {
                notifier.markCompleted(booking).catchError((_) {});
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            KynzaButton(
              label: gracePassed
                  ? 'Marquer absent'
                  : 'Marquer absent (dès +15 min)',
              variant: KynzaButtonVariant.secondary,
              onPressed: gracePassed
                  ? () {
                      notifier.markNoShow(booking.id!).catchError((_) {});
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            KynzaButton(
              label: 'Annuler ce RDV',
              variant: KynzaButtonVariant.destructive,
              onPressed: () async {
                final confirmed = await showKynzaConfirmDialog(
                  context,
                  title: 'Annuler ce RDV ?',
                  message: 'Le client sera notifié et remboursé si applicable.',
                );
                if (!confirmed) return;
                try {
                  await notifier.cancel(booking.id!, 'cancelled_by_salon');
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    showKynzaToast(
                      context,
                      message: e is AppException
                          ? e.message
                          : "Échec de l'annulation.",
                      level: ToastLevel.error,
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
