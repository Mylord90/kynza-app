import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_flow_provider.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/booking_list_card.dart';
import '../../../reviews/application/providers/review_providers.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/application/providers/service_providers.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() =>
      _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen> {
  bool _showUpcoming = true;

  Future<void> _rebook(BookingModel booking) async {
    final salon = await ref.read(salonByIdProvider(booking.salonId).future);
    final services = await ref.read(
      salonServicesProvider(booking.salonId).future,
    );
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;
    if (salon == null || service == null) return;
    ref
        .read(bookingFlowProvider.notifier)
        .prefillFastPass(salon: salon, service: service);
    if (mounted) context.go(RouteNames.clientBooking);
  }

  Future<void> _showReceipt(BookingModel booking) async {
    final salon = await ref.read(salonByIdProvider(booking.salonId).future);
    final services = await ref.read(
      salonServicesProvider(booking.salonId).future,
    );
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;
    if (salon == null || !mounted) return;
    showKynzaBottomSheet(
      context,
      builder: (_) => _ReceiptSheet(
        booking: booking,
        salonName: salon.name,
        serviceName: service?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(clientBookingsProvider(profile.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(context.l10n.bookingUpcomingTab),
              ),
              ButtonSegment(
                value: false,
                label: Text(context.l10n.bookingPastTab),
              ),
            ],
            selected: {_showUpcoming},
            onSelectionChanged: (s) => setState(() => _showUpcoming = s.first),
          ),
        ),
        Expanded(
          child: bookingsAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: KynzaSkeleton(height: 72),
              ),
            ),
            error: (_, __) => KynzaErrorState(
              message: context.l10n.errorLoadFailed,
              onRetry: () => ref.invalidate(clientBookingsProvider(profile.id)),
            ),
            data: (bookings) {
              final now = DateTime.now();
              final filtered =
                  bookings
                      .where(
                        (b) => _showUpcoming
                            ? b.startTime.isAfter(now)
                            : b.startTime.isBefore(now),
                      )
                      .toList()
                    ..sort(
                      (a, b) => _showUpcoming
                          ? a.startTime.compareTo(b.startTime)
                          : b.startTime.compareTo(a.startTime),
                    );
              if (filtered.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.event_note_outlined,
                  title: context.l10n.homeOwnerCalendarEmptyTitle,
                  subtitle: _showUpcoming
                      ? context.l10n.homeClientBookNextBeautyAppt
                      : "Vous n'avez pas encore d'historique.",
                  ctaLabel: context.l10n.bookingDiscoveryTitle,
                  onCta: () => context.go(RouteNames.clientDiscover),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final booking = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookingListCard(booking: booking),
                        if (!_showUpcoming)
                          _PastBookingActions(
                            booking: booking,
                            onRebook: () => _rebook(booking),
                            onReceipt: () => _showReceipt(booking),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PastBookingActions extends ConsumerWidget {
  const _PastBookingActions({
    required this.booking,
    required this.onRebook,
    required this.onReceipt,
  });

  final BookingModel booking;
  final VoidCallback onRebook;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReviewAsync = booking.id == null
        ? const AsyncValue.data(false)
        : ref.watch(canReviewProvider(booking.id!));

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (canReviewAsync.valueOrNull == true)
            KynzaButton(
              label: context.l10n.bookingLeaveReview,
              height: 36,
              onPressed: () =>
                  context.push(RouteNames.clientReviewPath(booking.id!)),
            ),
          KynzaButton(
            label: context.l10n.bookingRebookButton,
            height: 36,
            variant: KynzaButtonVariant.secondary,
            onPressed: onRebook,
          ),
          if (booking.isPaid)
            KynzaButton(
              label: context.l10n.bookingViewReceiptButton,
              height: 36,
              variant: KynzaButtonVariant.ghost,
              onPressed: onReceipt,
            ),
        ],
      ),
    );
  }
}

class _ReceiptSheet extends ConsumerWidget {
  const _ReceiptSheet({
    required this.booking,
    required this.salonName,
    this.serviceName,
  });

  final BookingModel booking;
  final String salonName;
  final String? serviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.bookingReceiptTitle, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          _ReceiptRow(
            label: context.l10n.bookingReceiptSalon,
            value: salonName,
          ),
          if (serviceName != null)
            _ReceiptRow(
              label: context.l10n.bookingReceiptService,
              value: serviceName!,
            ),
          _ReceiptRow(
            label: context.l10n.bookingReceiptDate,
            value:
                '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
          ),
          _ReceiptRow(
            label: context.l10n.bookingReceiptTime,
            value:
                '${booking.startTime.hour.toString().padLeft(2, '0')}:${booking.startTime.minute.toString().padLeft(2, '0')}',
          ),
          if (booking.paymentMethod != null)
            _ReceiptRow(
              label: context.l10n.bookingPaymentMethodLabel,
              value: booking.paymentMethod!,
            ),
          const Divider(color: AppColors.border),
          KynzaAmountWidget(amountBif: booking.amountBif),
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: context.l10n.bookingShareReceiptButton,
            onPressed: () => Share.share(
              '🧾 Reçu KYNZA — $salonName\n'
              '💰 ${CurrencyFormatter.formatBif(booking.amountBif)}\n'
              '📅 ${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.h3),
        ],
      ),
    );
  }
}
