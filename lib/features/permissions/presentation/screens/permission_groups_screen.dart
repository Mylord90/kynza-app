import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/permission_management_providers.dart';
import 'permission_group_form_sheet.dart';

class PermissionGroupsScreen extends ConsumerWidget {
  const PermissionGroupsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(permissionGroupsProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Groupes de permissions')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showKynzaBottomSheet(
          context,
          builder: (_) => PermissionGroupFormSheet(salonId: salonId),
        ),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: groupsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 72),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger les groupes de permissions.',
                onRetry: () =>
                    ref.invalidate(permissionGroupsProvider(salonId)),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.shield_outlined,
                    title: 'Aucun groupe de permissions',
                    subtitle:
                        'Créez un groupe pour donner à un membre de votre équipe des droits précis, au-delà de son rôle de base.',
                    ctaLabel: 'Créer un groupe',
                    onCta: () => showKynzaBottomSheet(
                      context,
                      builder: (_) =>
                          PermissionGroupFormSheet(salonId: salonId),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaCard(
                        onTap: () => context.push(
                          RouteNames.ownerPermissionGroupDetailPath(group.id),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(group.name, style: AppTypography.h3),
                                  if (group.description != null &&
                                      group.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        group.description!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: KynzaBadge(label: group.baseRole),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
