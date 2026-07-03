import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/remote_config_entry_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/remote_config_providers.dart';

class RemoteConfigScreen extends ConsumerWidget {
  const RemoteConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(remoteConfigRealtimeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionRemoteConfigTitle)),
      body: entriesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: KynzaSkeleton(height: 76),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.errorLoadFailed,
          onRetry: () => ref.invalidate(remoteConfigRealtimeProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.tune,
              title: context.l10n.evolutionRemoteConfigEmptyTitle,
              subtitle: context.l10n.evolutionRemoteConfigEmptySubtitle,
              ctaLabel: context.l10n.commonRetry,
              onCta: () => ref.invalidate(remoteConfigRealtimeProvider),
            );
          }

          final byCategory = <String, List<RemoteConfigEntryModel>>{};
          for (final entry in entries) {
            byCategory.putIfAbsent(entry.category, () => []).add(entry);
          }
          final categories = byCategory.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    category,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                ...byCategory[category]!.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ConfigEntryTile(entry: entry),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ConfigEntryTile extends ConsumerWidget {
  const _ConfigEntryTile({required this.entry});

  final RemoteConfigEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.key, style: AppTypography.body),
              ),
              IconButton(
                icon: const Icon(Icons.history, size: 20),
                color: AppColors.textMuted,
                tooltip: context.l10n.evolutionRemoteConfigHistoryTooltip,
                onPressed: () => _showHistorySheet(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
                tooltip: context.l10n.evolutionRemoteConfigEditTooltip,
                onPressed: () => _showEditSheet(context, ref),
              ),
            ],
          ),
          if (entry.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.description!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          KynzaBadge(label: jsonEncode(entry.valueJson)),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSheet(entry: entry),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(entry: entry),
    );
  }
}

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.entry});

  final RemoteConfigEntryModel entry;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _valueController;
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: jsonEncode(widget.entry.valueJson),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    dynamic parsed;
    try {
      parsed = jsonDecode(_valueController.text);
    } catch (_) {
      setState(() => _error = 'JSON invalide');
      return;
    }
    try {
      await ref
          .read(remoteConfigNotifierProvider.notifier)
          .updateEntry(
            key: widget.entry.key,
            value: parsed,
            changeReason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.evolutionRemoteConfigUpdateSuccess)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.entry.key, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                hintText: context.l10n.evolutionRemoteConfigNewValueHint,
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: context.l10n.evolutionRemoteConfigChangeReasonHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(context.l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.entry});

  final RemoteConfigEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(remoteConfigVersionsProvider(entry.id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.evolutionRemoteConfigHistoryTitle,
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            versionsAsync.when(
              loading: () => const KynzaSkeleton(height: 120),
              error: (_, __) => Text(context.l10n.errorLoadFailed),
              data: (versions) => Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return ListTile(
                      title: Text('v${version.versionNumber}'),
                      subtitle: Text(jsonEncode(version.valueJson)),
                      trailing: index == 0
                          ? null
                          : TextButton(
                              onPressed: () async {
                                await ref
                                    .read(remoteConfigNotifierProvider.notifier)
                                    .rollback(
                                      key: entry.key,
                                      versionNumber: version.versionNumber,
                                      entryId: entry.id,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context
                                            .l10n
                                            .evolutionRemoteConfigRollbackSuccess,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                context.l10n.evolutionRemoteConfigRollbackButton,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
