import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/constants/app_version.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/app_version_check_model.dart';
import '../../application/providers/version_providers.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionCheckProvider);
    final check = versionAsync.valueOrNull;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.evolutionForceUpdateTitle,
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  check?.message ?? context.l10n.evolutionForceUpdateDefaultMessage,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (check?.latestVersionName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _VersionChip(version: check!.latestVersionName!),
                ],
                const SizedBox(height: AppSpacing.xl),
                _UpdateButton(check: check),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: () => ref.invalidate(appVersionCheckProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(context.l10n.evolutionForceUpdateCheckButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        context.l10n.evolutionForceUpdateVersionLabel(version),
        style: AppTypography.label.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _UpdateButton extends StatefulWidget {
  const _UpdateButton({required this.check});

  final AppVersionCheckModel? check;

  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton> {
  bool _launching = false;

  Future<void> _openStore() async {
    setState(() => _launching = true);
    try {
      final url = Uri.parse(
        Platform.isAndroid ? kPlayStoreUrl : kAppStoreUrl,
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _launching ? null : _openStore,
        icon: _launching
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const Icon(Icons.download_rounded),
        label: Text(context.l10n.evolutionForceUpdateButton),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}