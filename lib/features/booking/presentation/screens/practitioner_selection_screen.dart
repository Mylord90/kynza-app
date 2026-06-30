import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/practitioner_card.dart';
import 'date_selection_screen.dart';

class PractitionerSelectionScreen extends ConsumerWidget {
  const PractitionerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    final salon = flowState.selectedSalon;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.bookingSelectPractitionerTitle)),
      body: salon == null
          ? KynzaErrorState(
              message: context.l10n.bookingNoSalonSelected,
              onRetry: _noop,
            )
          : Consumer(
              builder: (context, ref, _) {
                final staffAsync = ref.watch(salonStaffProvider(salon.id));
                return staffAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 3,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: KynzaSkeleton(height: 72),
                    ),
                  ),
                  error: (_, __) => KynzaErrorState(
                    message: context.l10n.bookingPractitionerLoadError,
                    onRetry: () => ref.invalidate(salonStaffProvider(salon.id)),
                  ),
                  data: (staff) {
                    final active = staff
                        .where((s) => s.isActive && !s.isPending)
                        .toList();

                    void choose(dynamic practitioner) {
                      ref
                          .read(bookingFlowProvider.notifier)
                          .selectPractitioner(practitioner);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DateSelectionScreen(),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: PractitionerCard(
                            practitioner: null,
                            isSelected: flowState.selectedPractitioner == null,
                            onTap: () => choose(null),
                          ),
                        ),
                        for (final member in active)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: PractitionerCard(
                              practitioner: member,
                              isSelected:
                                  flowState.selectedPractitioner?.id ==
                                  member.id,
                              onTap: () => choose(member),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

void _noop() {}
