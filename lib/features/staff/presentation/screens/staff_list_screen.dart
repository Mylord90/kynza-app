import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../journey/application/providers/journey_providers.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../team/presentation/widgets/staff_card_detailed.dart';
import '../../application/providers/staff_providers.dart';
import 'staff_detail_screen.dart';
import 'staff_invite_screen.dart';

const _filters = ['Actifs', 'En attente', 'Désactivés'];

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Équipe'),
        actions: [
          if (salon != null) ...[
            IconButton(
              icon: const Icon(Icons.payments_outlined),
              tooltip: 'Commissions',
              onPressed: () => context.push(RouteNames.ownerTeamCommissions),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffInviteScreen(salonId: salon.id),
                ),
              ),
              child: const Text(
                'Inviter',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
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

class _StaffBody extends ConsumerStatefulWidget {
  const _StaffBody({required this.salonId});

  final String salonId;

  @override
  ConsumerState<_StaffBody> createState() => _StaffBodyState();
}

class _StaffBodyState extends ConsumerState<_StaffBody> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(salonStaffProvider(widget.salonId));
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isOwner = profile?.role == UserRole.owner;

    return staffAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaStaffCardSkeleton(),
        ),
      ),
      error: (error, _) => KynzaErrorState(
        message: "Impossible de charger l'équipe.",
        onRetry: () => ref.invalidate(salonStaffProvider(widget.salonId)),
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
                      builder: (_) =>
                          StaffInviteScreen(salonId: widget.salonId),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: TextButton(
                  onPressed: () => ref
                      .read(journeyNotifierProvider.notifier)
                      .markStep(widget.salonId, 'team')
                      .catchError((_) {}),
                  child: const Text('Je travaille seul →'),
                ),
              ),
            ],
          );
        }
        ref
            .read(journeyNotifierProvider.notifier)
            .markStep(widget.salonId, 'team')
            .catchError((_) {});

        final active = staff.where((s) => s.isActive && !s.isPending).toList();
        final pending = staff.where((s) => s.isPending).toList();
        final disabled = staff
            .where((s) => !s.isActive && !s.isPending)
            .toList();
        final visible = switch (_filterIndex) {
          0 => active,
          1 => pending,
          _ => disabled,
        };

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _CountChip(label: 'actifs', count: active.length),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CountChip(
                      label: 'en attente',
                      count: pending.length,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CountChip(
                      label: 'désactivés',
                      count: disabled.length,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final selected = _filterIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        _filters[index],
                        style: AppTypography.bodySmall.copyWith(
                          color: selected
                              ? AppColors.background
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun membre dans cette catégorie.',
                        style: AppTypography.bodySmall,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(salonStaffProvider(widget.salonId)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final member = visible[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: StaffCardDetailed(
                              staff: member,
                              isOwner: isOwner,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StaffDetailScreen(staff: member),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('$count', style: AppTypography.h3),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
