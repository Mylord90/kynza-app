import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../application/providers/review_providers.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _anonymous = false;
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_rating == 0) {
      showKynzaToast(
        context,
        message: context.l10n.reviewsLeaveRatingRequired,
        level: ToastLevel.warning,
      );
      return;
    }
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final booking = await ref.read(
      bookingByIdProvider(widget.bookingId).future,
    );
    if (profile == null || booking == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(reviewNotifierProvider.notifier)
          .createReview(
            ReviewModel(
              salonId: booking.salonId,
              clientId: profile.id,
              bookingId: widget.bookingId,
              rating: _rating,
              comment: _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
              isAnonymous: _anonymous,
            ),
          );
      if (mounted) {
        final isOnline = ref.read(connectivityProvider).value ?? false;
        showKynzaToast(
          context,
          message: isOnline
              ? context.l10n.reviewsLeaveSuccess
              : context.l10n.reviewsLeaveQueuedOffline,
          level: ToastLevel.success,
        );
        context.pop();
      }
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReviewAsync = ref.watch(canReviewProvider(widget.bookingId));
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.reviewsLeaveTitle)),
      body: canReviewAsync.when(
        loading: () => const KynzaLoaderInline(size: KynzaLoaderSize.large),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.reviewsLeaveBookingError,
          onRetry: () => ref.invalidate(canReviewProvider(widget.bookingId)),
        ),
        data: (canReview) {
          if (!canReview) {
            return KynzaEmptyState(
              icon: Icons.rate_review_outlined,
              title: context.l10n.reviewsLeaveUnavailableTitle,
              subtitle: context.l10n.reviewsLeaveUnavailableSubtitle,
              ctaLabel: context.l10n.reviewsLeaveBackButton,
              onCta: () => context.pop(),
            );
          }
          return bookingAsync.when(
            loading: () => const KynzaLoaderInline(size: KynzaLoaderSize.large),
            error: (_, __) => const SizedBox.shrink(),
            data: (booking) {
              if (booking == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    booking.service?.name ??
                        context.l10n.reviewsLeaveServiceFallback,
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: _StarPicker(
                      rating: _rating,
                      onChanged: (v) {
                        KynzaHaptics.light();
                        setState(() => _rating = v);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  KynzaTextField(
                    label: context.l10n.reviewsLeaveCommentLabel,
                    controller: _commentCtrl,
                    maxLines: 4,
                    maxLength: 300,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.l10n.reviewsLeaveAnonymousLabel,
                      style: AppTypography.h3,
                    ),
                    value: _anonymous,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _anonymous = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  KynzaButton(
                    label: context.l10n.reviewsLeavePublishButton,
                    isLoading: _saving,
                    onPressed: _publish,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(context.l10n.reviewsLeaveSkipButton),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.rating, required this.onChanged});

  final int rating;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedScale(
              scale: i <= rating ? 1.15 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.elasticOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i <= rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
