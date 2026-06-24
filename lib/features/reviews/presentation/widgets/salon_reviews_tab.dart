import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/review_providers.dart';
import 'rating_summary_widget.dart';
import 'review_tile.dart';

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

class SalonReviewsTab extends ConsumerWidget {
  const SalonReviewsTab({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(salonRatingProvider(salonId));
    final reviewsAsync = ref.watch(salonReviewsProvider(salonId));
    final namesAsync = ref.watch(_reviewerNamesProvider(salonId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salonRatingProvider(salonId));
        ref.invalidate(salonReviewsProvider(salonId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          88,
        ),
        children: [
          ratingAsync.when(
            loading: () => const KynzaSkeleton(height: 110),
            error: (_, __) => const SizedBox.shrink(),
            data: (rating) => rating.totalReviews == 0
                ? const SizedBox.shrink()
                : RatingSummaryWidget(rating: rating),
          ),
          const SizedBox(height: AppSpacing.lg),
          reviewsAsync.when(
            loading: () => const KynzaSkeleton(height: 100, count: 3),
            error: (_, __) => KynzaErrorState(
              message: 'Impossible de charger les avis.',
              onRetry: () => ref.invalidate(salonReviewsProvider(salonId)),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const KynzaEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'Soyez le premier à laisser un avis !',
                  subtitle: 'Réservez puis partagez votre expérience.',
                  ctaLabel: 'Retour',
                  onCta: _noop,
                );
              }
              final names = namesAsync.valueOrNull ?? {};
              return Column(
                children: [
                  for (final review in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ReviewTile(
                        review: review,
                        clientName: names[review.clientId],
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
