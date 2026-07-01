import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/marketing/client_contact_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/marketing_providers.dart';

class InviteClientsScreen extends ConsumerStatefulWidget {
  const InviteClientsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<InviteClientsScreen> createState() =>
      _InviteClientsScreenState();
}

class _InviteClientsScreenState extends ConsumerState<InviteClientsScreen> {
  bool _showInvitations = false;
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _hiddenIds = <String>{};
  final _pendingTimers = <String, Timer>{};
  bool _importing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _scheduleDelete(ClientContactModel contact) {
    setState(() => _hiddenIds.add(contact.id!));
    final timer = Timer(const Duration(seconds: 4), () {
      ref
          .read(marketingNotifierProvider.notifier)
          .deleteContact(contact.id!)
          // Already shown as removed via _hiddenIds — there's no UI left
          // to surface a failure to at this point in the undo flow.
          .catchError((_) {});
      _pendingTimers.remove(contact.id);
    });
    _pendingTimers[contact.id!] = timer;

    final l10n = context.l10n;
    showKynzaToast(
      context,
      message: l10n.marketingClientsDeleteSuccess(contact.fullName),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(l10n.marketingClientsDeleteSuccess(contact.fullName)),
        action: SnackBarAction(
          label: l10n.commonCancel,
          onPressed: () {
            _pendingTimers.remove(contact.id)?.cancel();
            if (mounted) setState(() => _hiddenIds.remove(contact.id));
          },
        ),
      ),
    );
  }

  Future<void> _importFromBookings() async {
    setState(() => _importing = true);
    try {
      final count = await ref
          .read(marketingNotifierProvider.notifier)
          .importFromBookings(widget.salonId);
      if (!mounted) return;
      showKynzaToast(
        context,
        message: count == 0
            ? context.l10n.marketingImportNone
            : context.l10n.marketingImportCount(count),
        level: ToastLevel.success,
      );
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException
              ? e.message
              : context.l10n.marketingClientsImportError,
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _shareInvite(ClientContactModel contact) async {
    final salon = await ref.read(salonByIdProvider(widget.salonId).future);
    if (salon == null || contact.referralToken == null) return;
    await ShareService.shareClientInvite(salon, contact.referralToken!);
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(clientContactsProvider(widget.salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.marketingClientsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => showKynzaBottomSheet(
              context,
              builder: (_) => _AddContactSheet(salonId: widget.salonId),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.marketingClientsContactsTab),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.marketingClientsInvitationsTab),
                ),
              ],
              selected: {_showInvitations},
              onSelectionChanged: (s) =>
                  setState(() => _showInvitations = s.first),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: KynzaSkeleton(height: 64),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.marketingClientsLoadError,
                onRetry: () =>
                    ref.invalidate(clientContactsProvider(widget.salonId)),
              ),
              data: (allContacts) {
                final contacts = allContacts
                    .where((c) => !_hiddenIds.contains(c.id))
                    .where(
                      (c) => _showInvitations ? c.inviteSentAt != null : true,
                    )
                    .where(
                      (c) =>
                          _query.isEmpty ||
                          c.fullName.toLowerCase().contains(_query) ||
                          (c.phone ?? '').contains(_query),
                    )
                    .toList();

                if (_showInvitations) {
                  return _InvitationsList(contacts: contacts);
                }
                return _ContactsList(
                  contacts: contacts,
                  searchCtrl: _searchCtrl,
                  importing: _importing,
                  onSearchChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  onImport: _importFromBookings,
                  onDelete: _scheduleDelete,
                  onShare: _shareInvite,
                  onAddContact: () => showKynzaBottomSheet(
                    context,
                    builder: (_) => _AddContactSheet(salonId: widget.salonId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  const _ContactsList({
    required this.contacts,
    required this.searchCtrl,
    required this.importing,
    required this.onSearchChanged,
    required this.onImport,
    required this.onDelete,
    required this.onShare,
    required this.onAddContact,
  });

  final List<ClientContactModel> contacts;
  final TextEditingController searchCtrl;
  final bool importing;
  final void Function(String) onSearchChanged;
  final VoidCallback onImport;
  final void Function(ClientContactModel) onDelete;
  final void Function(ClientContactModel) onShare;
  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        KynzaTextField(
          hint: context.l10n.marketingSearchContactHint,
          controller: searchCtrl,
          onChanged: onSearchChanged,
          suffixIcon: const Icon(Icons.search),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaButton(
          label: context.l10n.marketingImportFromBookingsButton,
          variant: KynzaButtonVariant.secondary,
          isLoading: importing,
          onPressed: onImport,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (contacts.isEmpty)
          KynzaEmptyState(
            icon: Icons.people_outline,
            title: context.l10n.marketingNoContactsTitle,
            subtitle: context.l10n.marketingNoContactsSubtitle,
            ctaLabel: context.l10n.marketingAddContactButton,
            onCta: onAddContact,
          )
        else
          for (final contact in contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey(contact.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                ),
                onDismissed: (_) => onDelete(contact),
                child: KynzaCard(
                  child: Row(
                    children: [
                      KynzaAvatar(fullName: contact.fullName),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.fullName, style: AppTypography.h3),
                            if (contact.phone != null)
                              Text(
                                contact.phone!,
                                style: AppTypography.bodySmall,
                              ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                KynzaBadge(
                                  label: switch (contact.source) {
                                    'booking' =>
                                      context.l10n.contactSourceBooking,
                                    'referral' =>
                                      context.l10n.contactSourceReferral,
                                    _ => context.l10n.contactSourceManual,
                                  },
                                  variant: switch (contact.source) {
                                    'booking' => KynzaBadgeVariant.info,
                                    'referral' => KynzaBadgeVariant.gold,
                                    _ => KynzaBadgeVariant.neutral,
                                  },
                                ),
                                if (contact.isKynzaUser) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  KynzaBadge(
                                    label: context
                                        .l10n
                                        .marketingClientsOnKynzaBadge,
                                    variant: KynzaBadgeVariant.success,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => onShare(contact),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _InvitationsList extends StatelessWidget {
  const _InvitationsList({required this.contacts});

  final List<ClientContactModel> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return KynzaEmptyState(
        icon: Icons.send_outlined,
        title: context.l10n.marketingNoInvitationsSentTitle,
        subtitle: context.l10n.marketingNoInvitationsSentSubtitle,
        ctaLabel: context.l10n.commonBack,
        onCta: _noop,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final accepted = contact.inviteAcceptedAt != null;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: KynzaCard(
            child: Row(
              children: [
                KynzaAvatar(fullName: contact.fullName),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.fullName, style: AppTypography.h3),
                      Text(
                        context.l10n.marketingInviteSentOnDate(
                          _formatDate(contact.inviteSentAt!),
                        ),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                KynzaBadge(
                  label: accepted
                      ? context.l10n.marketingInviteAccepted
                      : context.l10n.marketingInviteSent,
                  variant: accepted
                      ? KynzaBadgeVariant.success
                      : KynzaBadgeVariant.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

void _noop() {}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet({required this.salonId});

  final String salonId;

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(marketingNotifierProvider.notifier)
          .addContact(
            ClientContactModel(
              salonId: widget.salonId,
              ownerId: profile.id,
              fullName: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim().isEmpty
                  ? null
                  : _phoneCtrl.text.trim(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException
              ? e.message
              : context.l10n.marketingContactAddError,
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              context.l10n.marketingAddContactTitle,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.marketingFullNameLabel,
              controller: _nameCtrl,
              validator: (v) =>
                  Validators.required(v, context.l10n.marketingFullNameLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaPhoneField(controller: _phoneCtrl),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: context.l10n.commonSave,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
