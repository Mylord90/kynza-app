import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/setting_field.dart';
import 'settings_category_screen.dart';

class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key, required this.salonId});

  final String salonId;

  void _openCategory(
    BuildContext context,
    String title,
    List<SettingField> fields,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsCategoryScreen(
          salonId: salonId,
          title: title,
          fields: fields,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SettingsTile(
            icon: Icons.shield_outlined,
            label: l10n.settingsPermissionsLabel,
            onTap: () => context.push(RouteNames.ownerPermissionGroups),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.bolt_outlined,
            label: l10n.settingsAutomationLabel,
            onTap: () => context.push(RouteNames.ownerAutomation),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.calendar_today_outlined,
            label: l10n.settingsBookingLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsBookingLabel,
              bookingSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: l10n.settingsNotificationsSalonLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsNotificationsSalonLabel,
              notificationSalonSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.campaign_outlined,
            label: l10n.settingsMarketingLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsMarketingLabel,
              marketingSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.people_outline,
            label: l10n.settingsTeamLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsTeamLabel,
              staffSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            label: l10n.settingsLoyaltyLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsLoyaltyLabel,
              loyaltySettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            label: l10n.settingsReviewsLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsReviewsLabel,
              reviewsSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.payments_outlined,
            label: l10n.settingsPaymentsLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsPaymentsLabel,
              paymentSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.tune_outlined,
            label: l10n.settingsAdvancedLabel,
            onTap: () => _openCategory(
              context,
              l10n.settingsAdvancedLabel,
              advancedSettingFields,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: l10n.settingsDocumentTemplatesLabel,
            onTap: () => context.push(RouteNames.ownerTemplates),
          ),
          _SettingsTile(
            icon: Icons.cloud_done_outlined,
            label: l10n.settingsDataBackupLabel,
            onTap: () => context.push(RouteNames.ownerBackup),
          ),
          _SettingsTile(
            icon: Icons.flag_outlined,
            label: l10n.settingsFeatureFlagsLabel,
            onTap: () => context.push(RouteNames.ownerFeatureFlags),
          ),
          _SettingsTile(
            icon: Icons.tune_outlined,
            label: l10n.settingsRemoteConfigLabel,
            onTap: () => context.push(RouteNames.ownerRemoteConfig),
          ),
          _SettingsTile(
            icon: Icons.monitor_heart_outlined,
            label: l10n.settingsHealthCenterLabel,
            onTap: () => context.push(RouteNames.ownerHealthCenter),
          ),
          _SettingsTile(
            icon: Icons.article_outlined,
            label: l10n.settingsCmsAdminLabel,
            onTap: () => context.push(RouteNames.ownerCmsAdmin),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: l10n.settingsHelpCenterLabel,
            onTap: () => context.push(RouteNames.helpCenter),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.language_outlined,
            label: l10n.settingsLanguageTitle,
            onTap: () => context.push(RouteNames.ownerLanguage),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            label: l10n.settingsAboutLabel,
            onTap: () => context.push(RouteNames.ownerAbout),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            label: l10n.legalCenterTitle,
            onTap: () => context.push(RouteNames.legalCenter),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.consentManagementTitle,
            onTap: () => context.push(RouteNames.settingsConsent),
          ),
          _SettingsTile(
            icon: Icons.folder_shared_outlined,
            label: l10n.dataRightsTitle,
            onTap: () => context.push(RouteNames.settingsDataRights),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: KynzaCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.h3)),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
