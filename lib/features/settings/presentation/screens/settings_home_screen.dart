import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SettingsTile(
            icon: Icons.shield_outlined,
            label: 'Permissions & Équipe',
            onTap: () => context.push(RouteNames.ownerPermissionGroups),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.bolt_outlined,
            label: 'Automatisations',
            onTap: () => context.push(RouteNames.ownerAutomation),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.calendar_today_outlined,
            label: 'Réservations',
            onTap: () =>
                _openCategory(context, 'Réservations', bookingSettingFields),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications du salon',
            onTap: () => _openCategory(
              context,
              'Notifications du salon',
              notificationSalonSettingFields,
            ),
          ),
          _SettingsTile(
            icon: Icons.campaign_outlined,
            label: 'Marketing',
            onTap: () =>
                _openCategory(context, 'Marketing', marketingSettingFields),
          ),
          _SettingsTile(
            icon: Icons.people_outline,
            label: 'Équipe',
            onTap: () => _openCategory(context, 'Équipe', staffSettingFields),
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            label: 'Fidélité',
            onTap: () =>
                _openCategory(context, 'Fidélité', loyaltySettingFields),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            label: 'Avis',
            onTap: () => _openCategory(context, 'Avis', reviewsSettingFields),
          ),
          _SettingsTile(
            icon: Icons.payments_outlined,
            label: 'Paiements',
            onTap: () =>
                _openCategory(context, 'Paiements', paymentSettingFields),
          ),
          _SettingsTile(
            icon: Icons.tune_outlined,
            label: 'Avancé',
            onTap: () =>
                _openCategory(context, 'Avancé', advancedSettingFields),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Modèles de documents',
            onTap: () => context.push(RouteNames.ownerTemplates),
          ),
          _SettingsTile(
            icon: Icons.cloud_done_outlined,
            label: 'Sauvegardes de données',
            onTap: () => context.push(RouteNames.ownerBackup),
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
