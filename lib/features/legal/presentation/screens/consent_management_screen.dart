import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/legal/legal_consent_setting_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';
import '../widgets/legal_labels.dart';

class ConsentManagementScreen extends ConsumerWidget {
  const ConsentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentsAsync = ref.watch(userLegalConsentsProvider);
    final saving = ref.watch(legalConsentNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.consentManagementTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: consentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: KynzaSkeleton(height: 280),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.consentManagementLoadError,
                onRetry: () => ref.invalidate(userLegalConsentsProvider),
              ),
              data: (consents) {
                bool grantedFor(LegalConsentType type) => consents
                    .firstWhere(
                      (c) => c.consentType == type,
                      orElse: () => LegalConsentSettingModel(
                        userId: '',
                        consentType: type,
                      ),
                    )
                    .granted;

                Future<void> toggle(LegalConsentType type, bool value) async {
                  try {
                    await ref
                        .read(legalConsentNotifierProvider.notifier)
                        .setConsent(type, value);
                  } catch (e) {
                    if (!context.mounted) return;
                    showKynzaToast(
                      context,
                      message: e is AppException
                          ? e.message
                          : context.l10n.consentManagementLoadError,
                      level: ToastLevel.error,
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    for (final type in LegalConsentType.values)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(legalConsentTypeLabel(context, type)),
                        subtitle: Text(legalConsentTypeSubtitle(context, type)),
                        value: grantedFor(type),
                        activeTrackColor: AppColors.primary,
                        onChanged: saving
                            ? null
                            : (v) => toggle(type, v),
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
