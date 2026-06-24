import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
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
      ref.read(marketingNotifierProvider.notifier).deleteContact(contact.id!);
      _pendingTimers.remove(contact.id);
    });
    _pendingTimers[contact.id!] = timer;

    showKynzaToast(context, message: '${contact.fullName} supprimé.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text('${contact.fullName} supprimé.'),
        action: SnackBarAction(
          label: 'Annuler',
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
    final count = await ref
        .read(marketingNotifierProvider.notifier)
        .importFromBookings(widget.salonId);
    if (mounted) setState(() => _importing = false);
    if (!mounted) return;
    showKynzaToast(
      context,
      message: count == null
          ? "Échec de l'import."
          : count == 0
          ? 'Aucun nouveau client à importer.'
          : '$count client(s) importé(s).',
      level: count == null ? ToastLevel.error : ToastLevel.success,
    );
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
        title: const Text('Mes Clients'),
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
              segments: const [
                ButtonSegment(value: false, label: Text('Contacts')),
                ButtonSegment(value: true, label: Text('Invitations')),
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
                message: 'Impossible de charger vos contacts.',
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
          hint: 'Rechercher un contact',
          controller: searchCtrl,
          onChanged: onSearchChanged,
          suffixIcon: const Icon(Icons.search),
        ),
        const SizedBox(height: AppSpacing.md),
        KynzaButton(
          label: 'Importer depuis les RDV',
          variant: KynzaButtonVariant.secondary,
          isLoading: importing,
          onPressed: onImport,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (contacts.isEmpty)
          KynzaEmptyState(
            icon: Icons.people_outline,
            title: 'Aucun contact encore',
            subtitle: 'Ajoutez vos premiers clients.',
            ctaLabel: 'Ajouter un contact',
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
                                    'booking' => 'RDV',
                                    'referral' => 'Parrainage',
                                    _ => 'Manuel',
                                  },
                                  variant: switch (contact.source) {
                                    'booking' => KynzaBadgeVariant.info,
                                    'referral' => KynzaBadgeVariant.gold,
                                    _ => KynzaBadgeVariant.neutral,
                                  },
                                ),
                                if (contact.isKynzaUser) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const KynzaBadge(
                                    label: 'Sur KYNZA ✓',
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
      return const KynzaEmptyState(
        icon: Icons.send_outlined,
        title: 'Aucune invitation envoyée',
        subtitle: 'Partagez un lien de parrainage depuis vos contacts.',
        ctaLabel: 'Retour',
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
                        'Envoyée le ${_formatDate(contact.inviteSentAt!)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                KynzaBadge(
                  label: accepted ? 'Acceptée' : 'Envoyée',
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
          message: e is AppException ? e.message : "Échec de l'ajout.",
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
            const Text('Ajouter un contact', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Nom complet *',
              controller: _nameCtrl,
              validator: (v) => Validators.required(v, 'Nom'),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaPhoneField(controller: _phoneCtrl),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: 'Enregistrer',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
