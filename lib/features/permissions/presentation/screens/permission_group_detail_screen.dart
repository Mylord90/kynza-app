import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/permission_definition_model.dart';
import '../../../../core/models/permission_group_model.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../application/providers/permission_management_providers.dart';

class PermissionGroupDetailScreen extends ConsumerWidget {
  const PermissionGroupDetailScreen({
    super.key,
    required this.salonId,
    required this.groupId,
  });

  final String salonId;
  final String groupId;

  PermissionGroupModel? _findGroup(List<PermissionGroupModel> groups) {
    for (final g in groups) {
      if (g.id == groupId) return g;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(permissionGroupsProvider(salonId));
    final group = groupsAsync.valueOrNull == null
        ? null
        : _findGroup(groupsAsync.valueOrNull!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(group?.name ?? 'Groupe de permissions'),
        actions: [
          if (group != null && !group.isSystem)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final confirmed = await showKynzaConfirmDialog(
                  context,
                  title: 'Supprimer ce groupe ?',
                  message:
                      'Les membres de "${group.name}" perdront les permissions accordées par ce groupe.',
                  confirmLabel: 'Supprimer',
                );
                if (!confirmed) return;
                await ref
                    .read(permissionGroupNotifierProvider.notifier)
                    .deleteGroup(salonId: salonId, groupId: groupId);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: KynzaSpinner()),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger ce groupe.',
                onRetry: () =>
                    ref.invalidate(permissionGroupsProvider(salonId)),
              ),
              data: (_) {
                if (group == null) {
                  return const KynzaEmptyState(
                    icon: Icons.error_outline,
                    title: 'Groupe introuvable',
                    subtitle: 'Ce groupe a peut-être été supprimé.',
                    ctaLabel: 'Retour',
                    onCta: _noop,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _MembersSection(salonId: salonId, groupId: groupId),
                    const SizedBox(height: AppSpacing.xl),
                    const Text('Permissions', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    _PermissionsSection(groupId: groupId),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _PermissionsSection extends ConsumerWidget {
  const _PermissionsSection({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(permissionCatalogProvider);
    final grantedAsync = ref.watch(groupPermissionIdsProvider(groupId));

    if (catalogAsync.isLoading || grantedAsync.isLoading) {
      return Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: KynzaSkeleton(height: 56),
          ),
        ),
      );
    }
    if (catalogAsync.hasError || grantedAsync.hasError) {
      return KynzaErrorState(
        message: 'Impossible de charger les permissions.',
        onRetry: () {
          ref.invalidate(permissionCatalogProvider);
          ref.invalidate(groupPermissionIdsProvider(groupId));
        },
      );
    }

    final catalog = catalogAsync.value!;
    final granted = grantedAsync.value!;
    final byFeature = <String, List<PermissionDefinitionModel>>{};
    for (final p in catalog) {
      byFeature.putIfAbsent(p.feature, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byFeature.entries.map((entry) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              entry.key,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            children: entry.value.map((permission) {
              final isGranted = granted.contains(permission.id);
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                value: isGranted,
                title: Text(permission.label, style: AppTypography.bodySmall),
                onChanged: (value) => ref
                    .read(permissionGroupNotifierProvider.notifier)
                    .setGroupPermission(
                      groupId: groupId,
                      permissionId: permission.id,
                      granted: value,
                    ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _MembersSection extends ConsumerWidget {
  const _MembersSection({required this.salonId, required this.groupId});

  final String salonId;
  final String groupId;

  StaffProfileModel? _findStaffByUserId(
    List<StaffProfileModel> staff,
    String userId,
  ) {
    for (final s in staff) {
      if (s.userId == userId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberIdsAsync = ref.watch(groupMemberUserIdsProvider(groupId));
    final staffAsync = ref.watch(salonStaffProvider(salonId));
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Membres', style: AppTypography.h2),
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _showAddMemberSheet(
                context,
                ref,
                staffAsync.valueOrNull ?? const [],
                memberIdsAsync.valueOrNull ?? const [],
                profile?.id ?? '',
              ),
            ),
          ],
        ),
        if (memberIdsAsync.isLoading || staffAsync.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: KynzaSkeleton(height: 56),
          )
        else
          ..._memberTiles(
            ref,
            memberIdsAsync.valueOrNull ?? const [],
            staffAsync.valueOrNull ?? const [],
          ),
      ],
    );
  }

  List<Widget> _memberTiles(
    WidgetRef ref,
    List<String> memberIds,
    List<StaffProfileModel> staff,
  ) {
    if (memberIds.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'Aucun membre dans ce groupe pour le moment.',
            style: AppTypography.bodySmall,
          ),
        ),
      ];
    }
    return memberIds.map((userId) {
      final member = _findStaffByUserId(staff, userId);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: KynzaCard(
          child: Row(
            children: [
              KynzaAvatar(fullName: member?.displayName ?? 'Membre'),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  member?.displayName ?? userId,
                  style: AppTypography.body,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.error,
                ),
                onPressed: () => ref
                    .read(permissionGroupNotifierProvider.notifier)
                    .removeMember(groupId: groupId, userId: userId),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showAddMemberSheet(
    BuildContext context,
    WidgetRef ref,
    List<StaffProfileModel> staff,
    List<String> currentMemberIds,
    String grantedBy,
  ) {
    final candidates = staff
        .where((s) => s.userId != null && !currentMemberIds.contains(s.userId))
        .toList();

    showKynzaBottomSheet(
      context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ajouter un membre', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  "Toute l'équipe fait déjà partie de ce groupe.",
                  style: AppTypography.body,
                ),
              )
            else
              ...candidates.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: KynzaAvatar(fullName: s.displayName),
                  title: Text(s.displayName),
                  subtitle: Text(s.role),
                  onTap: () {
                    ref
                        .read(permissionGroupNotifierProvider.notifier)
                        .addMember(
                          salonId: salonId,
                          groupId: groupId,
                          userId: s.userId!,
                          grantedBy: grantedBy,
                        );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
