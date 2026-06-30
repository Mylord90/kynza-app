import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/kynza_constants.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../payment/presentation/screens/payment_screen.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/booking_summary_card.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    await ref
        .read(bookingFlowProvider.notifier)
        .submitBooking(
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    final state = ref.read(bookingFlowProvider);
    if (!mounted) return;
    if (state.createdBooking != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(booking: state.createdBooking!),
        ),
      );
    } else if (state.error != null) {
      showKynzaToast(context, message: state.error!, level: ToastLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.bookingSummaryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          BookingSummaryCard(state: state),
          const SizedBox(height: AppSpacing.lg),
          KynzaTextField(
            label: context.l10n.bookingSummaryNotesLabel,
            controller: _notesCtrl,
            maxLines: 3,
            maxLength: KynzaConstants.maxNoteChars,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Text(
              context.l10n.bookingSummaryPaymentLockWarning,
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          KynzaButton(
            label: context.l10n.bookingSummarySubmitButton,
            isLoading: state.isLoading,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
