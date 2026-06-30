import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/review_providers.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/review_tile.dart';

enum _SortMode { recent, lowestRating, unansweredFirst }

final _reviewerNamesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, salonId) async {
      final reviews = await ref.watch(salonReviewsProvider(salonId).future);
      final ids = reviews.map((r) => r.clientId).toSet().toList();
      if (ids.isEmpty) return {};
      final rows = await SupabaseService.from(
        'users',
      ).select('id, full_name').inFilter('id', ids);
      return {
        for (final row in rows) row['id'] as String: row['full_name'] as String,
      };
    });

class OwnerReviewsScreen extends ConsumerStatefulWidget {
  const OwnerReviewsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends ConsumerState<OwnerReviewsScreen> {
  _SortMode _sort = _SortMode.recent;

  Future<void> _reply(ReviewModel review) async {
    final replyCtrl = TextEditingController();
    await showKynzaBottomSheet(
      context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.reviewsReplyTitle, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.reviewsReplyLabel,
              controller: replyCtrl,
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaButton(
              label: context.l10n.reviewsReplySubmitButton,
              onPressed: () async {
                if (replyCtrl.text.trim().isEmpty) return;
                try {
                  await ref
                      .read(reviewNotifierProvider.notifier)
                      .replyToReview(
                        widget.salonId,
                        review.id!,
                        replyCtrl.text.trim(),
                      );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                } catch (e) {
                  if (mounted) {
                    showKynzaToast(
                      context,
                      message: e is AppException
                          ? e.message
                          : context.l10n.reviewsReplyError,
                      level: ToastLevel.error,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _flag(ReviewModel review) async {
    final confirmed = await showKynzaConfirmDialog(
      context,
      title: context.l10n.reviewsFlagConfirmTitle,
      message: context.l10n.reviewsFlagConfirmMessage,
      confirmLabel: context.l10n.reviewsFlagConfirmButton,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(reviewNotifierProvider.notifier)
          .flagReview(widget.salonId, review.id!);
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : context.l10n.reviewsFlagError,
          level: ToastLevel.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingAsync = ref.watch(salonRatingProvider(widget.salonId));
    final reviewsAsync = ref.watch(salonReviewsProvider(widget.salonId));
    final namesAsync = ref.watch(_reviewerNamesProvider(widget.salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.reviewsOwnerTitle),
        actions: [
          ratingAsync.maybeWhen(
            data: (rating) => rating.totalReviews == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: Center(
                      child: KynzaBadge(
                        label: '★ ${rating.averageRating.toStringAsFixed(1)}',
                        variant: KynzaBadgeVariant.gold,
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ratingAsync.when(
            loading: () => const KynzaSkeleton(height: 100),
            error: (_, __) => const SizedBox.shrink(),
            data: (rating) => rating.totalReviews == 0
                ? const SizedBox.shrink()
                : RatingSummaryWidget(rating: rating, compact: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<_SortMode>(
            segments: [
              ButtonSegment(
                value: _SortMode.recent,
                label: Text(context.l10n.reviewsSortRecent),
              ),
              ButtonSegment(
                value: _SortMode.lowestRating,
                label: Text(context.l10n.reviewsSortLowest),
              ),
              ButtonSegment(
                value: _SortMode.unansweredFirst,
                label: Text(context.l10n.reviewsSortUnanswered),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (s) => setState(() => _sort = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          reviewsAsync.when(
            loading: () => const Column(
              children: [
                KynzaReviewCardSkeleton(),
                SizedBox(height: AppSpacing.sm),
                KynzaReviewCardSkeleton(),
                SizedBox(height: AppSpacing.sm),
                KynzaReviewCardSkeleton(),
              ],
            ),
            error: (_, __) => KynzaErrorState(
              message: context.l10n.reviewsLoadError,
              onRetry: () =>
                  ref.invalidate(salonReviewsProvider(widget.salonId)),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: context.l10n.reviewsEmptyTitle,
                  subtitle: context.l10n.reviewsEmptySubtitle,
                  ctaLabel: context.l10n.reviewsEmptyCta,
                  onCta: _noop,
                );
              }
              final sorted = [...reviews];
              switch (_sort) {
                case _SortMode.recent:
                  sorted.sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );
                case _SortMode.lowestRating:
                  sorted.sort((a, b) => a.rating.compareTo(b.rating));
                case _SortMode.unansweredFirst:
                  sorted.sort(
                    (a, b) => (a.hasOwnerReply ? 1 : 0).compareTo(
                      b.hasOwnerReply ? 1 : 0,
                    ),
                  );
              }
              final names = namesAsync.valueOrNull ?? {};
              return Column(
                children: [
                  for (final review in sorted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ReviewTile(
                        review: review,
                        clientName: names[review.clientId],
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!review.hasOwnerReply)
                              IconButton(
                                icon: const Icon(
                                  Icons.reply_outlined,
                                  size: 20,
                                ),
                                onPressed: () => _reply(review),
                              ),
                            IconButton(
                              icon: const Icon(Icons.flag_outlined, size: 20),
                              onPressed: () => _flag(review),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

void _noop() {}
