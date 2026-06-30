import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../booking/presentation/widgets/booking_list_card.dart';
import '../../../loyalty/application/providers/loyalty_providers.dart';
import '../../../loyalty/presentation/widgets/loyalty_card_widget.dart';
import '../../../notifications/presentation/screens/notification_settings_screen.dart';
import '../../../salon/presentation/widgets/media_upload_button.dart';
import '../../application/providers/client_profile_providers.dart';

final _myReviewCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = SupabaseService.auth.currentUser?.id;
  if (uid == null) return 0;
  final rows = await SupabaseService.from(
    'reviews',
  ).select('id').eq('client_id', uid).isFilter('deleted_at', null);
  return rows.length;
});

final _myReviewsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final uid = SupabaseService.auth.currentUser?.id;
      if (uid == null) return [];
      final rows = await SupabaseService.from('reviews')
          .select('rating, comment, created_at, salons:salon_id(name)')
          .eq('client_id', uid)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return rows;
    });

final _myReferralTokenProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final uid = SupabaseService.auth.currentUser?.id;
  if (uid == null) return null;
  final existing = await SupabaseService.from('referrals')
      .select('referral_token')
      .eq('referrer_id', uid)
      .isFilter('salon_id', null)
      .maybeSingle();
  if (existing != null) return existing['referral_token'] as String;
  final row = await SupabaseService.from(
    'referrals',
  ).insert({'referrer_id': uid}).select('referral_token').single();
  return row['referral_token'] as String;
});

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(clientBookingsProvider(profile.id));
    final cardsAsync = ref.watch(clientLoyaltyCardsProvider);
    final reviewCountAsync = ref.watch(_myReviewCountProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // SECTION 1 — Avatar header
        Center(
          child: Column(
            children: [
              MediaUploadButton(
                isCircular: true,
                width: 80,
                height: 80,
                previewUrl: profile.avatarUrl,
                isLoading: ref.watch(clientProfileNotifierProvider).isLoading,
                onPicked: (bytes, ext) async {
                  try {
                    await ref
                        .read(clientProfileNotifierProvider.notifier)
                        .uploadAvatar(bytes, ext);
                  } catch (e) {
                    if (context.mounted) {
                      showKynzaToast(
                        context,
                        message: e is AppException
                            ? e.message
                            : l10n.homeClientProfileAvatarUploadError,
                        level: ToastLevel.error,
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(profile.fullName, style: AppTypography.h2),
              if (profile.phone != null)
                Text(profile.phone!, style: AppTypography.body),
              if (profile.email != null)
                Text(profile.email!, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              KynzaBadge(
                label: profile.role.name,
                variant: KynzaBadgeVariant.gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 2 — Mes informations
        Text(l10n.homeClientProfileInfoTitle, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        KynzaCard(
          onTap: () => showKynzaBottomSheet(
            context,
            builder: (_) => _EditProfileSheet(profile: profile),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: AppTypography.h3),
                    Text(
                      profile.phone ?? l10n.homeClientProfileNoPhone,
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      profile.email ?? l10n.homeClientProfileNoEmail,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 3 — Mes RDV récents
        Text(l10n.homeClientProfileRecentBookingsTitle, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        bookingsAsync.when(
          loading: () => const KynzaSkeleton(height: 72, count: 2),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            if (bookings.isEmpty) {
              return Text(
                l10n.homeClientProfileNoBookings,
                style: AppTypography.body,
              );
            }
            final recent = [...bookings]
              ..sort((a, b) => b.startTime.compareTo(a.startTime));
            return Column(
              children: [
                for (final booking in recent.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: BookingListCard(booking: booking),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.clientBookings),
                    child: Text(l10n.homeClientProfileSeeAllBookings),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 4 — Mes fidélités
        Text(l10n.homeClientProfileLoyaltiesTitle, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        cardsAsync.when(
          loading: () => const KynzaSkeleton(height: 100),
          error: (_, __) => const SizedBox.shrink(),
          data: (cards) {
            if (cards.isEmpty) {
              return Text(
                l10n.homeClientProfileNoLoyalty,
                style: AppTypography.body,
              );
            }
            return Column(
              children: [
                LoyaltyCardWidget(card: cards.first),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.clientLoyalty),
                    child: Text(l10n.homeClientProfileSeeAllPrograms),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 5 — Mes avis
        Text(l10n.homeClientProfileReviewsTitle, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        reviewCountAsync.when(
          loading: () => const KynzaSkeleton(height: 24),
          error: (_, __) => const SizedBox.shrink(),
          data: (count) => Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeClientProfileReviewCount(count),
                  style: AppTypography.body,
                ),
              ),
              TextButton(
                onPressed: () => showKynzaBottomSheet(
                  context,
                  builder: (_) => const _MyReviewsSheet(),
                ),
                child: Text(l10n.homeClientProfileSeeAllReviews),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 6 — Notifications
        KynzaCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.navNotifications, style: AppTypography.h3),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 6b — Langue
        KynzaCard(
          onTap: () => context.push(RouteNames.ownerLanguage),
          child: Row(
            children: [
              const Icon(Icons.language, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.settingsLanguageTitle, style: AppTypography.h3),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 7 — Partager KYNZA
        Consumer(
          builder: (context, ref, _) {
            final tokenAsync = ref.watch(_myReferralTokenProvider);
            return KynzaCard(
              onTap: () async {
                final token = tokenAsync.valueOrNull;
                if (token != null) {
                  await ShareService.shareGenericInvite(token);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.favorite_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      context.l10n.homeClientProfileInviteFriend,
                      style: AppTypography.h3,
                    ),
                  ),
                  const Icon(Icons.share_outlined, color: AppColors.textMuted),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        // SECTION 8 — Déconnexion
        KynzaButton(
          label: l10n.authLogout,
          variant: KynzaButtonVariant.destructive,
          onPressed: () async {
            final confirmed = await showKynzaConfirmDialog(
              context,
              title: l10n.homeClientProfileLogoutTitle,
              message: l10n.homeClientProfileLogoutMessage,
              confirmLabel: l10n.homeClientProfileLogoutButton,
            );
            if (confirmed) {
              await ref.read(authNotifierProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.profile.fullName);
  late final _phoneCtrl = TextEditingController(text: widget.profile.phone);
  late final _emailCtrl = TextEditingController(text: widget.profile.email);
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(clientProfileNotifierProvider.notifier)
          .updateProfile(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException
              ? e.message
              : context.l10n.homeClientProfileUpdateError,
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.homeClientProfileEditTitle, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: l10n.authCompleteProfileFullNameLabel,
              controller: _nameCtrl,
              validator: Validators.fullName,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: l10n.homeClientProfilePhoneLabel,
              controller: _phoneCtrl,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: l10n.authLoginEmailLabel,
              controller: _emailCtrl,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: l10n.commonSave,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReviewsSheet extends ConsumerWidget {
  const _MyReviewsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reviewsAsync = ref.watch(_myReviewsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeClientProfileReviewsTitle, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: reviewsAsync.when(
              loading: () => const KynzaSkeleton(height: 60, count: 3),
              error: (_, __) => Text(
                l10n.homeClientProfileReviewsLoadError,
                style: AppTypography.body,
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Text(
                    l10n.homeClientProfileNoReviews,
                    style: AppTypography.body,
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final salonName =
                        (review['salons'] as Map?)?['name'] ?? 'Salon';
                    final rating = review['rating'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: KynzaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$salonName', style: AppTypography.h3),
                            Text(
                              '★' * rating + '☆' * (5 - rating),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            if (review['comment'] != null)
                              Text(
                                review['comment'] as String,
                                style: AppTypography.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
