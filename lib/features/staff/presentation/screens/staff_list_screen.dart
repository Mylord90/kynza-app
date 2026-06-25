import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../journey/application/providers/journey_providers.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/staff_providers.dart';
import '../widgets/staff_card.dart';
import 'staff_form_screen.dart';
import 'staff_invite_screen.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Équipe')),
      floatingActionButton: salon == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(
                Icons.person_add_outlined,
                color: AppColors.background,
              ),
              label: const Text(
                'Inviter un membre',
                style: TextStyle(color: AppColors.background),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffInviteScreen(salonId: salon.id),
                ),
              ),
            ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          if (salon != null) Expanded(child: _StaffBody(salonId: salon.id)),
        ],
      ),
    );
  }
}

class _StaffBody extends ConsumerWidget {
  const _StaffBody({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(salonStaffProvider(salonId));

    return staffAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 72),
        ),
      ),
      error: (error, _) => KynzaErrorState(
        message: "Impossible de charger l'équipe.",
        onRetry: () => ref.invalidate(salonStaffProvider(salonId)),
      ),
      data: (staff) {
        if (staff.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: KynzaEmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Aucun membre',
                  subtitle:
                      'Invitez votre équipe pour commencer à organiser le '
                      'planning, ou travaillez seul pour commencer.',
                  ctaLabel: 'Inviter un membre',
                  onCta: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StaffInviteScreen(salonId: salonId),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: TextButton(
                  onPressed: () => ref
                      .read(journeyNotifierProvider.notifier)
                      .markStep(salonId, 'team')
                      .catchError((_) {}),
                  child: const Text('Je travaille seul →'),
                ),
              ),
            ],
          );
        }
        // Staff already exists — the "team" journey step is implicitly
        // satisfied; idempotent, so safe to call on every rebuild.
        ref
            .read(journeyNotifierProvider.notifier)
            .markStep(salonId, 'team')
            .catchError((_) {});
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final member = staff[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: StaffCard(
                staff: member,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StaffFormScreen(staff: member),
                  ),
                ),
                onToggleActive: (active) => ref
                    .read(staffNotifierProvider.notifier)
                    .toggleActive(member.id!, active)
                    .catchError((_) {}),
              ),
            );
          },
        );
      },
    );
  }
}
