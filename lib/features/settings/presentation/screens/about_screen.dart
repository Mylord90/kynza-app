import 'package:flutter/material.dart';
import '../../../../core/constants/app_branding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = DateTime.now().year.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settingsAboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  AppBranding.logoFull,
                  height: 88,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'KYNZA',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${l10n.settingsAboutVersionLabel} $kAppVersionName',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          KynzaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsAboutSectionApp,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: l10n.settingsAboutVersionLabel,
                  value: kAppVersionName,
                ),
                _InfoRow(
                  label: l10n.settingsAboutBuildLabel,
                  value: '$kAppVersionCode',
                ),
                _InfoRow(
                  label: l10n.settingsAboutPlatformLabel,
                  value: kAppPlatform,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsAboutSectionLegal,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: l10n.settingsAboutPublisherLabel,
                  value: 'KYNZA SAS',
                ),
                _InfoRow(
                  label: l10n.settingsAboutCountryLabel,
                  value: 'Burundi',
                ),
                _InfoRow(
                  label: l10n.settingsAboutCurrencyLabel,
                  value: 'Franc Burundais (FBu)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            l10n.settingsAboutCopyright(year),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}
