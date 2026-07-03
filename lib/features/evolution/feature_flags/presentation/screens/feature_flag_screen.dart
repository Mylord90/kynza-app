import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/enums/user_role.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/role_feature_override_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../../../../core/models/user_feature_override_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/feature_flag_providers.dart';
import 'feature_flag_audit_screen.dart';

class FeatureFlagScreen extends ConsumerWidget {
  const FeatureFlagScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final overridesAsync = ref.watch(salonFeatureOverridesProvider(salonId));
    final roleOverridesAsync = ref.watch(roleFeatureOverridesProvider(salonId));
    final userOverridesAsync = ref.watch(userFeatureOverridesProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.evolutionFeatureFlagsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: context.l10n.evolutionFeatureFlagsAuditTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FeatureFlagAuditScreen(salonId: salonId),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: Builder(
              builder: (context) {
                final loading =
                    flagsAsync.isLoading ||
                    overridesAsync.isLoading ||
                    roleOverridesAsync.isLoading ||
                    userOverridesAsync.isLoading;
                if (loading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaSkeleton(height: 88),
                    ),
                  );
                }
                final hasError =
                    flagsAsync.hasError ||
                    overridesAsync.hasError ||
                    roleOverridesAsync.hasError ||
                    userOverridesAsync.hasError;
                if (hasError) {
                  return KynzaErrorState(
                    message: context.l10n.errorLoadFailed,
                    onRetry: () {
                      ref.invalidate(featureFlagsProvider);
                      ref.invalidate(salonFeatureOverridesProvider(salonId));
                      ref.invalidate(roleFeatureOverridesProvider(salonId));
                      ref.invalidate(userFeatureOverridesProvider(salonId));
                    },
                  );
                }

                final flags = flagsAsync.value!;
                final overrides = overridesAsync.value!;
                final roleOverrides = roleOverridesAsync.value!;
                final userOverrides = userOverridesAsync.value!;
                final overrideByKey = {for (final o in overrides) o.flagKey: o};

                if (flags.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.flag_outlined,
                    title: context.l10n.evolutionFeatureFlagsEmptyTitle,
                    subtitle: context.l10n.evolutionFeatureFlagsEmptySubtitle,
                    ctaLabel: context.l10n.commonRetry,
                    onCta: () => ref.invalidate(featureFlagsProvider),
                  );
                }

                final byCategory = <String, List<FeatureFlagModel>>{};
                for (final flag in flags) {
                  byCategory.putIfAbsent(flag.category, () => []).add(flag);
                }
                final categories = byCategory.keys.toList()..sort();

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const _InfoCard(),
                    const SizedBox(height: AppSpacing.md),
                    for (final category in categories) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          category,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      ...byCategory[category]!.map(
                        (flag) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _FlagTile(
                            flag: flag,
                            flagOverride: overrideByKey[flag.key],
                            roleOverrides: roleOverrides
                                .where((o) => o.flagKey == flag.key)
                                .toList(),
                            userOverrides: userOverrides
                                .where((o) => o.flagKey == flag.key)
                                .toList(),
                            salonId: salonId,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.evolutionFeatureFlagsInfoText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagTile extends ConsumerWidget {
  const _FlagTile({
    required this.flag,
    required this.flagOverride,
    required this.roleOverrides,
    required this.userOverrides,
    required this.salonId,
  });

  final FeatureFlagModel flag;
  final SalonFeatureOverrideModel? flagOverride;
  final List<RoleFeatureOverrideModel> roleOverrides;
  final List<UserFeatureOverrideModel> userOverrides;
  final String salonId;

  bool get _effectiveValue => flagOverride?.isEnabled ?? flag.isEnabled;
  bool get _hasOverride => flagOverride != null;
  bool get _hasScopedOverrides =>
      roleOverrides.isNotEmpty || userOverrides.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(featureFlagNotifierProvider.notifier);

    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasOverride ? Icons.flag : Icons.flag_outlined,
                color: _hasOverride ? AppColors.primary : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(flag.name, style: AppTypography.body)),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20,
                  color: _hasScopedOverrides
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                tooltip: context.l10n.evolutionFeatureFlagsScopeTooltip,
                onPressed: () => _showScopeSheet(context, ref),
              ),
              Switch(
                value: _effectiveValue,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => notifier.setOverride(
                  salonId: salonId,
                  flagKey: flag.key,
                  isEnabled: value,
                ),
              ),
              if (_hasOverride)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  tooltip: context.l10n.evolutionFeatureFlagsResetTooltip,
                  // No padding/constraints override — the default 48x48
                  // minimum tap target applies (was previously stripped to
                  // ~18x18px, a WCAG 2.5.5 Target Size failure found and
                  // fixed in Phase 8 of the Enterprise Hardening pass).
                  onPressed: () => notifier.removeOverride(
                    salonId: salonId,
                    flagKey: flag.key,
                  ),
                ),
            ],
          ),
          if (flag.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                flag.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              children: [
                _GlobalBadge(flag: flag),
                if (_hasOverride) ...[
                  const SizedBox(width: AppSpacing.xs),
                  KynzaBadge(
                    label: context.l10n.evolutionFeatureFlagsOverrideBadge,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScopeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ScopeSheet(
        flag: flag,
        salonId: salonId,
        roleOverrides: roleOverrides,
        userOverrides: userOverrides,
      ),
    );
  }
}

class _GlobalBadge extends StatelessWidget {
  const _GlobalBadge({required this.flag});

  final FeatureFlagModel flag;

  @override
  Widget build(BuildContext context) {
    if (!flag.isEnabled) {
      return KynzaBadge(label: context.l10n.evolutionFeatureFlagsDisabledBadge);
    }
    if (flag.rolloutPercentage < 100) {
      return KynzaBadge(
        label: context.l10n.evolutionFeatureFlagsRollout(
          flag.rolloutPercentage,
        ),
      );
    }
    return KynzaBadge(label: context.l10n.evolutionFeatureFlagsEnabledBadge);
  }
}

/// Scope editor: per-role toggles (owner/manager/staff/client, salon-scoped)
/// and a single per-user override by raw user ID. Deliberately a plain text
/// field rather than a user picker/search — this is an internal enterprise
/// admin surface, not a client-facing flow; a user-search UX is a follow-up,
/// not required for the underlying engine (role/user overrides, Realtime
/// propagation, audit trail) to be real and provably working.
class _ScopeSheet extends ConsumerStatefulWidget {
  const _ScopeSheet({
    required this.flag,
    required this.salonId,
    required this.roleOverrides,
    required this.userOverrides,
  });

  final FeatureFlagModel flag;
  final String salonId;
  final List<RoleFeatureOverrideModel> roleOverrides;
  final List<UserFeatureOverrideModel> userOverrides;

  @override
  ConsumerState<_ScopeSheet> createState() => _ScopeSheetState();
}

class _ScopeSheetState extends ConsumerState<_ScopeSheet> {
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(featureFlagNotifierProvider.notifier);
    final roleByName = {for (final o in widget.roleOverrides) o.role: o};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.flag.name, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.evolutionFeatureFlagsRoleOverridesTitle,
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final role in UserRole.values)
              _RoleOverrideRow(
                role: role.name,
                overrideModel: roleByName[role.name],
                onChanged: (value) => notifier.setRoleOverride(
                  salonId: widget.salonId,
                  role: role.name,
                  flagKey: widget.flag.key,
                  isEnabled: value,
                ),
                onReset: roleByName[role.name] == null
                    ? null
                    : () => notifier.removeRoleOverride(
                        salonId: widget.salonId,
                        role: role.name,
                        flagKey: widget.flag.key,
                      ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.evolutionFeatureFlagsUserOverridesTitle,
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                hintText: context.l10n.evolutionFeatureFlagsUserIdHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setUserOverride(notifier, true),
                    child: Text(context.l10n.evolutionFeatureFlagsEnabledBadge),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setUserOverride(notifier, false),
                    child: Text(
                      context.l10n.evolutionFeatureFlagsDisabledBadge,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.userOverrides.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final o in widget.userOverrides)
                _UserOverrideRow(
                  overrideModel: o,
                  onRemove: () => notifier.removeUserOverride(
                    salonId: widget.salonId,
                    userId: o.userId,
                    flagKey: widget.flag.key,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _setUserOverride(FeatureFlagNotifier notifier, bool isEnabled) {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.evolutionFeatureFlagsUserIdEmpty)),
      );
      return;
    }
    notifier.setUserOverride(
      salonId: widget.salonId,
      userId: userId,
      flagKey: widget.flag.key,
      isEnabled: isEnabled,
    );
    _userIdController.clear();
  }
}

class _RoleOverrideRow extends StatelessWidget {
  const _RoleOverrideRow({
    required this.role,
    required this.overrideModel,
    required this.onChanged,
    required this.onReset,
  });

  final String role;
  final RoleFeatureOverrideModel? overrideModel;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(role, style: AppTypography.body)),
        Switch(
          value: overrideModel?.isEnabled ?? false,
          onChanged: onChanged,
        ),
        if (onReset != null)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textMuted,
            onPressed: onReset,
          ),
      ],
    );
  }
}

class _UserOverrideRow extends StatelessWidget {
  const _UserOverrideRow({required this.overrideModel, required this.onRemove});

  final UserFeatureOverrideModel overrideModel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${overrideModel.userId} → ${overrideModel.isEnabled}',
            style: AppTypography.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.textMuted,
          onPressed: onRemove,
        ),
      ],
    );
  }
}
