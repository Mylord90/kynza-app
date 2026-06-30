import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../models/language_enum.dart';

class LanguageSelectorTile extends ConsumerWidget {
  const LanguageSelectorTile({super.key, required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(languageProvider);
    final isSelected = currentCode == language.code;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Text(language.flagEmoji, style: const TextStyle(fontSize: 28)),
      title: Text(language.nativeName, style: AppTypography.body),
      subtitle: Text(
        language.englishName,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined, color: AppColors.textMuted),
      onTap: () {
        if (!isSelected) {
          ref.read(languageProvider.notifier).setLanguage(language.code);
        }
      },
    );
  }
}
