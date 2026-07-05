import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/maintenance_providers.dart';

/// SYSTEM_ADMIN-only — create/delete a scheduled maintenance window.
/// Closes P3-11 (Master Plan Execution CP3): previously the only way to
/// schedule a maintenance window was a raw SQL INSERT.
class MaintenanceAdminScreen extends ConsumerWidget {
  const MaintenanceAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(upcomingMaintenanceWindowsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Maintenance windows')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger les fenêtres de maintenance.',
          onRetry: () => ref.invalidate(upcomingMaintenanceWindowsProvider),
        ),
        data: (windows) {
          if (windows.isEmpty) {
            return const Center(
              child: Text(
                'Aucune fenêtre de maintenance planifiée.',
                style: AppTypography.body,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: windows.length,
            itemBuilder: (context, index) {
              final w = windows[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: KynzaCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w['title'] as String,
                              style: AppTypography.body,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${w['starts_at']} -> ${w['ends_at']}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(maintenanceAdminNotifierProvider.notifier)
                            .deleteWindow(w['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateWindowSheet(),
    );
  }
}

class _CreateWindowSheet extends ConsumerStatefulWidget {
  const _CreateWindowSheet();

  @override
  ConsumerState<_CreateWindowSheet> createState() =>
      _CreateWindowSheetState();
}

class _CreateWindowSheetState extends ConsumerState<_CreateWindowSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  final DateTime _endsAt = DateTime.now().add(const Duration(hours: 2));

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(maintenanceAdminNotifierProvider.notifier)
        .createWindow(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          startsAt: _startsAt,
          endsAt: _endsAt,
        );
    if (mounted) Navigator.of(context).pop();
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
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Titre'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Message affiché aux utilisateurs',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Planifier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
