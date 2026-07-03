import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class SupportContactScreen extends StatelessWidget {
  const SupportContactScreen({super.key});

  static const _supportEmail = 'support@kynza.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.supportContactTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            context.l10n.supportContactDescription,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          KynzaCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(context.l10n.supportContactEmailLabel),
              subtitle: const Text(_supportEmail),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => context.push(
              RouteNames.legalDocumentPath('support-policy'),
            ),
            child: Text(context.l10n.supportContactPolicyLink),
          ),
        ],
      ),
    );
  }
}
