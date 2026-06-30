import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/booking_calendar_widget.dart';
import 'time_slot_screen.dart';

class DateSelectionScreen extends ConsumerWidget {
  const DateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.bookingSelectDateTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: BookingCalendarWidget(
          selectedDate: flowState.selectedDate,
          onDateSelected: (date) {
            ref.read(bookingFlowProvider.notifier).selectDate(date);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TimeSlotScreen()));
          },
        ),
      ),
    );
  }
}
