import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/notification_preferences_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferencesModel? _draft;
  late final _phoneCtrl = TextEditingController();

  void _ensureDraft(NotificationPreferencesModel prefs) {
    _draft ??= prefs;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final saving = ref.watch(notificationNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.notificationsSettingsTitle)),
      body: prefsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 240),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.notificationsLoadError,
          onRetry: () => ref.invalidate(notificationPrefsProvider),
        ),
        data: (prefs) {
          if (profile == null) return const SizedBox.shrink();
          final current =
              prefs ?? NotificationPreferencesModel.defaultsFor(profile.id);
          _ensureDraft(current);
          final draft = _draft!;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                context.l10n.notificationsChannelsHeading,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsPushTitle),
                value: draft.pushEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(pushEnabled: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsWhatsappTitle),
                value: draft.whatsappEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(whatsappEnabled: v)),
              ),
              if (draft.whatsappEnabled) ...[
                const SizedBox(height: AppSpacing.sm),
                KynzaTextField(
                  label: context.l10n.notificationsWhatsappLabel,
                  hint: context.l10n.notificationsWhatsappHint,
                  controller: _phoneCtrl,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.l10n.notificationsAlertTypesHeading,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsBookingCreatedTitle),
                subtitle: Text(
                  context.l10n.notificationsBookingCreatedSubtitle,
                ),
                value: draft.bookingCreated,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(bookingCreated: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsBookingConfirmedTitle),
                value: draft.bookingConfirmed,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _draft = draft.copyWith(bookingConfirmed: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsBookingCancelledTitle),
                value: draft.bookingCancelled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _draft = draft.copyWith(bookingCancelled: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsRemindersTitle),
                subtitle: Text(context.l10n.notificationsRemindersSubtitle),
                value: draft.remindersEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _draft = draft.copyWith(
                    bookingReminder24h: v,
                    bookingReminder2h: v,
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsTeamTitle),
                subtitle: Text(context.l10n.notificationsTeamSubtitle),
                value: draft.staffEvents,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(staffEvents: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.notificationsMarketingTitle),
                subtitle: Text(context.l10n.notificationsMarketingSubtitle),
                value: draft.marketing,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(marketing: v)),
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: context.l10n.notificationsSaveButton,
                isLoading: saving,
                onPressed: () async {
                  final phone = _phoneCtrl.text.trim();
                  try {
                    await ref
                        .read(notificationNotifierProvider.notifier)
                        .updatePrefs(draft.copyWith(userId: profile.id));
                    if (phone.isNotEmpty) {
                      await ref
                          .read(notificationNotifierProvider.notifier)
                          .updateWhatsappPhone(profile.id, phone);
                    }
                    if (context.mounted) {
                      showKynzaToast(
                        context,
                        message: context.l10n.notificationsSaveSuccess,
                        level: ToastLevel.success,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showKynzaToast(
                        context,
                        message: e is AppException
                            ? e.message
                            : context.l10n.notificationsSaveError,
                        level: ToastLevel.error,
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
