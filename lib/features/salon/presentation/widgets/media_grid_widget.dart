import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/salon_media_model.dart';
import '../../../../shared/widgets/kynza_confirm_dialog.dart';

const kMaxPortfolioItems = 20;

/// 3-column portfolio grid. Long-press drags a tile to reorder; tap opens
/// a full-screen preview; the X badge soft-deletes (with confirmation, R15).
class MediaGridWidget extends StatelessWidget {
  const MediaGridWidget({
    super.key,
    required this.media,
    required this.onDelete,
    required this.onReorder,
    this.trailing,
  });

  final List<SalonMediaModel> media;
  final void Function(String mediaId) onDelete;
  final void Function(List<String> orderedIds) onReorder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: media.length + (trailing != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == media.length) return trailing!;
        final item = media[index];
        return LongPressDraggable<int>(
          data: index,
          feedback: _Thumbnail(item: item, dragging: false, scaled: true),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _Thumbnail(item: item, dragging: false),
          ),
          child: DragTarget<int>(
            onAcceptWithDetails: (details) {
              final from = details.data;
              if (from == index) return;
              final next = [...media];
              final moved = next.removeAt(from);
              next.insert(index, moved);
              onReorder(next.map((m) => m.id!).toList());
            },
            builder: (context, candidates, rejects) => GestureDetector(
              onTap: () => _openPreview(context, item),
              child: Stack(
                children: [
                  _Thumbnail(item: item, dragging: candidates.isNotEmpty),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _DeleteBadge(
                      onTap: () async {
                        final confirmed = await showKynzaConfirmDialog(
                          context,
                          title: context.l10n.salonMediaDeleteTitle,
                          message: context.l10n.salonMediaDeleteMessage,
                        );
                        if (confirmed) onDelete(item.id!);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPreview(BuildContext context, SalonMediaModel item) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: item.thumbnailUrl ?? item.url),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.item,
    required this.dragging,
    this.scaled = false,
  });

  final SalonMediaModel item;
  final bool dragging;
  final bool scaled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: scaled ? 100 : null,
      height: scaled ? 100 : null,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md_,
        border: Border.all(
          color: dragging ? AppColors.primary : AppColors.border,
          width: dragging ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.thumbnailUrl ?? item.url,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: AppColors.surfaceVariant),
            errorWidget: (context, url, error) =>
                Container(color: AppColors.surfaceVariant),
          ),
          if (item.type == MediaType.video)
            const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.close, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
