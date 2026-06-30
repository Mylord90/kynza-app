import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/salon_settings_providers.dart';
import '../widgets/setting_field.dart';

class SettingsCategoryScreen extends ConsumerWidget {
  const SettingsCategoryScreen({
    super.key,
    required this.salonId,
    required this.title,
    required this.fields,
  });

  final String salonId;
  final String title;
  final List<SettingField> fields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(salonSettingsProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: settingsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: fields.length,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 56),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.settingsCategoryLoadError,
                onRetry: () => ref.invalidate(salonSettingsProvider(salonId)),
              ),
              data: (settings) {
                final values = settings.toJson();
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: fields.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return _SettingFieldTile(
                      salonId: salonId,
                      field: field,
                      value: values[field.key],
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

class _SettingFieldTile extends ConsumerWidget {
  const _SettingFieldTile({
    required this.salonId,
    required this.field,
    required this.value,
  });

  final String salonId;
  final SettingField field;
  final dynamic value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = field.resolveLabel(context.l10n);
    if (field.type == SettingFieldType.boolean) {
      return KynzaCard(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primary,
          value: value as bool,
          title: Text(label, style: AppTypography.body),
          onChanged: (next) => ref
              .read(salonSettingsNotifierProvider.notifier)
              .updateField(salonId, field.key, value, next),
        ),
      );
    }

    return KynzaCard(
      onTap: () => _showEditSheet(context, ref),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          Text(
            '$value',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final label = field.resolveLabel(context.l10n);
    final controller = TextEditingController(text: '$value');
    showKynzaBottomSheet<void>(
      context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            KynzaTextField(
              controller: controller,
              keyboardType: field.type == SettingFieldType.integer
                  ? TextInputType.number
                  : TextInputType.text,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaButton(
              label: sheetContext.l10n.commonSave,
              onPressed: () {
                final next = field.type == SettingFieldType.integer
                    ? (int.tryParse(controller.text) ?? value)
                    : controller.text;
                ref
                    .read(salonSettingsNotifierProvider.notifier)
                    .updateField(salonId, field.key, value, next);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
