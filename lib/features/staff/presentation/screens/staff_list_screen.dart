import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
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

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.staffListTitle),
        actions: [
          if (salon != null) ...[
            IconButton(
              icon: const Icon(Icons.payments_outlined),
              tooltip: context.l10n.staffListCommissionsTooltip,
              onPressed: () => context.push(RouteNames.ownerTeamCommissions),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffInviteScreen(salonId: salon.id),
                ),
              ),
              child: Text(
                context.l10n.commonAdd,
                style: const TextStyle(color: AppColors.primary),
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

  List<String> _filters(BuildContext context) => [
    context.l10n.staffFilterActive,
    context.l10n.staffFilterPending,
    context.l10n.staffFilterDisabled,
  ];

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
        message: context.l10n.staffListLoadError,
        onRetry: () => ref.invalidate(salonStaffProvider(widget.salonId)),
      ),
      data: (staff) {
        if (staff.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: KynzaEmptyState(
                  icon: Icons.groups_outlined,
                  title: context.l10n.staffInviteTitle,
                  subtitle: context.l10n.staffListEmptySubtitle,
                  ctaLabel: context.l10n.staffInviteTitle,
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
                  child: Text(context.l10n.staffListSoloLink),
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
                    child: _CountChip(
                      label: context.l10n.staffCountActive,
                      count: active.length,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CountChip(
                      label: context.l10n.staffCountPending,
                      count: pending.length,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CountChip(
                      label: context.l10n.staffCountDisabled,
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
                itemCount: _filters(context).length,
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
                        _filters(context)[index],
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
                  ? Center(
                      child: Text(
                        context.l10n.staffNoMembersInCategory,
                        style: AppTypography.bodySmall,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
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
