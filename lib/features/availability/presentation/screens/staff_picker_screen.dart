import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../staff/application/providers/staff_providers.dart';

/// "Choose a staff member" intermediate step shared by "Horaires par
/// staff" and "Pauses & absences" — both need the same picker, just a
/// different destination once one is selected.
class StaffPickerScreen extends ConsumerWidget {
  const StaffPickerScreen({
    super.key,
    required this.salonId,
    required this.title,
    required this.onSelect,
  });

  final String salonId;
  final String title;
  final void Function(StaffProfileModel staff) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(salonStaffProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: staffAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: KynzaSkeleton(height: 64),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.availabilityStaffLoadError,
          onRetry: () => ref.invalidate(salonStaffProvider(salonId)),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.people_outline,
              title: context.l10n.availabilityNoStaffTitle,
              subtitle: context.l10n.availabilityNoStaffSubtitle,
              ctaLabel: context.l10n.commonBack,
              onCta: _noop,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: KynzaCard(
                  onTap: () => onSelect(member),
                  child: Row(
                    children: [
                      KynzaAvatar(
                        fullName: member.displayName,
                        avatarUrl: member.avatarUrl,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          member.displayName,
                          style: AppTypography.h3,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _noop() {}
