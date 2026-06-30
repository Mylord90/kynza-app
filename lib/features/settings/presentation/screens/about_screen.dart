import 'package:flutter/material.dart';
import '../../../../core/constants/app_branding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('À propos')),
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
                  'Version $kAppVersionName',
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
                Text('Application', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                const _InfoRow(label: 'Version', value: kAppVersionName),
                const _InfoRow(label: 'Build', value: '$kAppVersionCode'),
                _InfoRow(label: 'Plateforme', value: kAppPlatform),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Légal', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                const _InfoRow(label: 'Éditeur', value: 'KYNZA SAS'),
                const _InfoRow(label: 'Pays', value: 'Burundi'),
                const _InfoRow(label: 'Devise', value: 'Franc Burundais (FBu)'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            '© ${DateTime.now().year} KYNZA. Tous droits réservés.',
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
          Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}