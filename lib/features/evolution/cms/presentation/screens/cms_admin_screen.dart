import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/cms_content_model.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/cms_providers.dart';

/// SYSTEM_ADMIN-only CRUD surface — create/edit/publish/unpublish, locale
/// aware. Gated the same way as Health Center (`_SystemAdminGuard` at the
/// router level).
class CmsAdminScreen extends ConsumerWidget {
  const CmsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(cmsAdminListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.evolutionCmsAdminTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditSheet(context, ref, existing: null),
        child: const Icon(Icons.add),
      ),
      body: listAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: KynzaSkeleton(height: 76),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.errorLoadFailed,
          onRetry: () => ref.invalidate(cmsAdminListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.article_outlined,
              title: context.l10n.evolutionCmsAdminEmptyTitle,
              subtitle: context.l10n.evolutionCmsAdminEmptySubtitle,
              ctaLabel: context.l10n.evolutionCmsCreateButton,
              onCta: () => _showEditSheet(context, ref, existing: null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: KynzaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.type} · ${item.slug} · ${item.locale}',
                              style: AppTypography.body,
                            ),
                          ),
                          KynzaBadge(label: item.status.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.title, style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () =>
                                _showEditSheet(context, ref, existing: item),
                            child: Text(context.l10n.commonSave),
                          ),
                          TextButton(
                            onPressed: () => ref
                                .read(cmsNotifierProvider.notifier)
                                .setStatus(
                                  id: item.id,
                                  status: item.isPublished
                                      ? 'unpublished'
                                      : 'published',
                                ),
                            child: Text(
                              item.isPublished
                                  ? context.l10n.evolutionCmsUnpublishButton
                                  : context.l10n.evolutionCmsPublishButton,
                            ),
                          ),
                        ],
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

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref, {
    required CmsContentModel? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CmsEditSheet(existing: existing),
    );
  }
}

class _CmsEditSheet extends ConsumerStatefulWidget {
  const _CmsEditSheet({required this.existing});

  final CmsContentModel? existing;

  @override
  ConsumerState<_CmsEditSheet> createState() => _CmsEditSheetState();
}

class _CmsEditSheetState extends ConsumerState<_CmsEditSheet> {
  late final TextEditingController _typeController;
  late final TextEditingController _slugController;
  late final TextEditingController _localeController;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _typeController = TextEditingController(text: e?.type ?? 'help_article');
    _slugController = TextEditingController(text: e?.slug ?? '');
    _localeController = TextEditingController(text: e?.locale ?? 'fr');
    _titleController = TextEditingController(text: e?.title ?? '');
    _bodyController = TextEditingController(text: e?.bodyMarkdown ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _slugController.dispose();
    _localeController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(cmsNotifierProvider.notifier);
    if (widget.existing == null) {
      await notifier.create(
        type: _typeController.text.trim(),
        slug: _slugController.text.trim(),
        locale: _localeController.text.trim(),
        title: _titleController.text.trim(),
        bodyMarkdown: _bodyController.text,
      );
    } else {
      await notifier.updateContent(
        id: widget.existing!.id,
        title: _titleController.text.trim(),
        bodyMarkdown: _bodyController.text,
      );
    }
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
            if (widget.existing == null) ...[
              TextField(
                controller: _typeController,
                decoration: InputDecoration(
                  hintText: context.l10n.evolutionCmsTypeHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _slugController,
                decoration: InputDecoration(
                  hintText: context.l10n.evolutionCmsSlugHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _localeController,
                decoration: InputDecoration(
                  hintText: context.l10n.evolutionCmsLocaleHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: context.l10n.evolutionCmsTitleHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: context.l10n.evolutionCmsBodyHint,
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
