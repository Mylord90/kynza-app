import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/document_template_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/template_providers.dart';
import 'template_editor_screen.dart';

const _typeLabels = {
  'invoice': 'Facture',
  'receipt': 'Reçu',
  'monthly_report': 'Rapport mensuel',
};

const _typeIcons = {
  'invoice': Icons.receipt_long_outlined,
  'receipt': Icons.confirmation_number_outlined,
  'monthly_report': Icons.bar_chart_outlined,
};

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (salonId: salonId, type: null);
    final templatesAsync = ref.watch(templatesProvider(query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modèles de documents')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: templatesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: KynzaSkeleton(height: 72),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: 'Impossible de charger les modèles.',
                onRetry: () => ref.invalidate(templatesProvider(query)),
              ),
              data: (templates) => templates.isEmpty
                  ? KynzaEmptyState(
                      icon: Icons.description_outlined,
                      title: 'Aucun modèle',
                      subtitle:
                          'Créez des modèles personnalisés pour vos factures, reçus et rapports.',
                      ctaLabel: 'Créer un modèle',
                      onCta: () => _openEditor(context, ref, null),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: templates.length,
                      itemBuilder: (context, index) => _TemplateTile(
                        salonId: salonId,
                        template: templates[index],
                        onEdit: () =>
                            _openEditor(context, ref, templates[index]),
                        onDelete: () =>
                            _confirmDelete(context, ref, templates[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref,
    DocumentTemplateModel? existing,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(
          salonId: salonId,
          existing: existing,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DocumentTemplateModel template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer le modèle'),
        content: Text('Supprimer « ${template.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(templateNotifierProvider.notifier)
          .deleteTemplate(template.id, salonId, template.type);
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: 'Modèle supprimé.',
        level: ToastLevel.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      showKynzaToast(
        context,
        message: 'Impossible de supprimer ce modèle.',
        level: ToastLevel.error,
      );
    }
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.salonId,
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final String salonId;
  final DocumentTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[template.type] ?? Icons.description_outlined;
    final typeLabel = _typeLabels[template.type] ?? template.type;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        onTap: onEdit,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(template.name, style: AppTypography.h3),
                      ),
                      if (template.isDefault)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.xs),
                          child: KynzaBadge(label: 'DÉFAUT'),
                        ),
                    ],
                  ),
                  Text(
                    typeLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}