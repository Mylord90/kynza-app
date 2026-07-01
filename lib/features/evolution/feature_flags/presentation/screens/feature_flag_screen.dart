import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/feature_flag_model.dart';
import '../../../../../core/models/salon_feature_override_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/feature_flag_providers.dart';

class FeatureFlagScreen extends ConsumerWidget {
  const FeatureFlagScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final overridesAsync = ref.watch(salonFeatureOverridesProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionFeatureFlagsTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (flagsAsync.isLoading || overridesAsync.isLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaSkeleton(height: 88),
                    ),
                  );
                }
                if (flagsAsync.hasError || overridesAsync.hasError) {
                  return KynzaErrorState(
                    message: context.l10n.errorLoadFailed,
                    onRetry: () {
                      ref.invalidate(featureFlagsProvider);
                      ref.invalidate(salonFeatureOverridesProvider(salonId));
                    },
                  );
                }

                final flags = flagsAsync.value!;
                final overrides = overridesAsync.value!;
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

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const _InfoCard(),
                    const SizedBox(height: AppSpacing.md),
                    ...flags.map(
                      (flag) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _FlagTile(
                          flag: flag,
                          flagOverride: overrideByKey[flag.key],
                          salonId: salonId,
                        ),
                      ),
                    ),
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
    required this.salonId,
  });

  final FeatureFlagModel flag;
  final SalonFeatureOverrideModel? flagOverride;
  final String salonId;

  bool get _effectiveValue => flagOverride?.isEnabled ?? flag.isEnabled;
  bool get _hasOverride => flagOverride != null;

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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
