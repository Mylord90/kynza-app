import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/router/route_names.dart';
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
              label: context.l10n.bookingDetailCompleteAndCollect,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(RouteNames.ownerProxiPayPath(booking.id!));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            KynzaButton(
              label: gracePassed
                  ? context.l10n.bookingDetailMarkAbsent
                  : context.l10n.bookingDetailMarkAbsentGrace,
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
              label: context.l10n.bookingDetailCancelButton,
              variant: KynzaButtonVariant.destructive,
              onPressed: () async {
                final confirmed = await showKynzaConfirmDialog(
                  context,
                  title: context.l10n.homeOwnerBookingCancelConfirmTitle,
                  message: context.l10n.homeOwnerBookingCancelConfirmMessage,
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
