import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/booking_summary_card.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spring,
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) context.go(RouteNames.homeClient);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 96,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '✅ Payé ! Votre place est réservée.',
              style: AppTypography.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Réf. ${widget.booking.id?.substring(0, 8).toUpperCase()}',
                style: AppTypography.mono,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            BookingSummaryCard(state: flowState, compact: true),
            const SizedBox(height: AppSpacing.lg),
            KynzaButton(
              label: 'Ajouter au calendrier',
              variant: KynzaButtonVariant.secondary,
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://calendar.google.com/calendar/render?action=TEMPLATE'
                  '&text=${Uri.encodeComponent('RDV KYNZA')}'
                  '&dates=${_fmt(widget.booking.startTime)}/${_fmt(widget.booking.endTime)}',
                ),
              ),
            ),
            if (flowState.selectedSalon != null &&
                flowState.selectedService != null) ...[
              const SizedBox(height: AppSpacing.md),
              KynzaButton(
                label: 'Partager',
                variant: KynzaButtonVariant.ghost,
                onPressed: () => ShareService.shareBooking(
                  booking: widget.booking,
                  salon: flowState.selectedSalon!,
                  service: flowState.selectedService!,
                  practitioner: flowState.selectedPractitioner,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            KynzaButton(
              label: "Retour à l'accueil",
              variant: KynzaButtonVariant.ghost,
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).reset();
                context.go(RouteNames.homeClient);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
}
