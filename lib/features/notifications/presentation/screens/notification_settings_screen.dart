import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
      appBar: AppBar(title: const Text('Préférences de notifications')),
      body: prefsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 240),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger vos préférences.',
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
              const Text('Canaux', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications push'),
                value: draft.pushEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(pushEnabled: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('WhatsApp'),
                value: draft.whatsappEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(whatsappEnabled: v)),
              ),
              if (draft.whatsappEnabled) ...[
                const SizedBox(height: AppSpacing.sm),
                KynzaTextField(
                  label: 'Numéro WhatsApp',
                  hint: '+257 ...',
                  controller: _phoneCtrl,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const Text("Types d'alertes", style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Réservation créée'),
                subtitle: const Text('Confirmation immédiate de votre demande'),
                value: draft.bookingCreated,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(bookingCreated: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('RDV confirmé'),
                value: draft.bookingConfirmed,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _draft = draft.copyWith(bookingConfirmed: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('RDV annulé'),
                value: draft.bookingCancelled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(
                  () => _draft = draft.copyWith(bookingCancelled: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rappels RDV'),
                subtitle: const Text('Rappel 24h et 2h avant le rendez-vous'),
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
                title: const Text('Équipe'),
                subtitle: const Text(
                  'Invitations et arrivées de collaborateurs',
                ),
                value: draft.staffEvents,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(staffEvents: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marketing'),
                subtitle: const Text('Promotions et nouveautés du salon'),
                value: draft.marketing,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(marketing: v)),
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: 'Enregistrer',
                isLoading: saving,
                onPressed: () async {
                  final phone = _phoneCtrl.text.trim();
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
                      message: 'Préférences enregistrées.',
                      level: ToastLevel.success,
                    );
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
