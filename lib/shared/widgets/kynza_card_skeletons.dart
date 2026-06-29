import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import 'kynza_card.dart';
import 'kynza_skeleton.dart';

/// Named skeleton placeholders shaped like their real card counterparts —
/// each composes the generic [KynzaSkeleton] bar so the shimmer animation
/// stays identical everywhere; only the layout differs per card type.
class KynzaBookingCardSkeleton extends StatelessWidget {
  const KynzaBookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KynzaSkeleton(width: 160, height: 16),
                SizedBox(height: AppSpacing.xs),
                KynzaSkeleton(width: 90, height: 14),
              ],
            ),
          ),
          KynzaSkeleton(width: 64, height: 24, radius: 12),
        ],
      ),
    );
  }
}

class KynzaServiceCardSkeleton extends StatelessWidget {
  const KynzaServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KynzaSkeleton(width: 140, height: 16),
                SizedBox(height: AppSpacing.xs),
                KynzaSkeleton(width: 110, height: 13),
                SizedBox(height: AppSpacing.xs),
                KynzaSkeleton(width: 70, height: 14),
              ],
            ),
          ),
          KynzaSkeleton(width: 40, height: 24, radius: 12),
        ],
      ),
    );
  }
}

class KynzaStaffCardSkeleton extends StatelessWidget {
  const KynzaStaffCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Row(
        children: [
          KynzaSkeleton(width: 40, height: 40, isRound: true),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KynzaSkeleton(width: 130, height: 16),
                SizedBox(height: AppSpacing.xs),
                KynzaSkeleton(width: 80, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KynzaAnalyticsCardSkeleton extends StatelessWidget {
  const KynzaAnalyticsCardSkeleton({super.key, this.chartHeight = 140});

  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KynzaSkeleton(width: 120, height: 16),
          const SizedBox(height: AppSpacing.md),
          KynzaSkeleton(height: chartHeight, radius: 12),
        ],
      ),
    );
  }
}

class KynzaNotificationItemSkeleton extends StatelessWidget {
  const KynzaNotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Row(
        children: [
          KynzaSkeleton(width: 36, height: 36, isRound: true),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KynzaSkeleton(width: double.infinity, height: 14),
                SizedBox(height: AppSpacing.xs),
                KynzaSkeleton(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KynzaReviewCardSkeleton extends StatelessWidget {
  const KynzaReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KynzaSkeleton(width: 90, height: 14),
          SizedBox(height: AppSpacing.sm),
          KynzaSkeleton(width: double.infinity, height: 13),
          SizedBox(height: AppSpacing.xs),
          KynzaSkeleton(width: 200, height: 13),
        ],
      ),
    );
  }
}

class KynzaLoyaltyCardSkeleton extends StatelessWidget {
  const KynzaLoyaltyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KynzaSkeleton(width: 120, height: 16),
          SizedBox(height: AppSpacing.md),
          KynzaSkeleton(height: 48, radius: 12),
        ],
      ),
    );
  }
}
