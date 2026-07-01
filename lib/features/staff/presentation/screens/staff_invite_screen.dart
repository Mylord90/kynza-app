import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/staff_providers.dart';

class StaffInviteScreen extends ConsumerStatefulWidget {
  const StaffInviteScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<StaffInviteScreen> createState() => _StaffInviteScreenState();
}

class _StaffInviteScreenState extends ConsumerState<StaffInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'staff';
  bool _isSending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final callerRole =
        ref.read(currentUserProfileProvider).valueOrNull?.role ??
        UserRole.staff;

    try {
      final staff = await ref
          .read(staffRepositoryProvider)
          .inviteStaff(
            salonId: widget.salonId,
            displayName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: _role,
            callerRole: callerRole.name,
          );
      ref.invalidate(salonStaffProvider(widget.salonId));

      if (!mounted) return;
      final salon = await ref.read(salonByIdProvider(widget.salonId).future);
      if (!mounted) return;
      await ShareService.shareStaffInvitation(
        salonName: salon?.name ?? 'KYNZA',
        invitationToken: staff.invitationToken ?? '',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException
              ? e.message
              : context.l10n.staffInviteError,
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final callerRole = ref.watch(currentUserProfileProvider).valueOrNull?.role;
    final canAssignManager = callerRole == UserRole.owner;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.staffInviteTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            KynzaTextField(
              label: context.l10n.staffInviteNameLabel,
              controller: _nameCtrl,
              validator: (v) =>
                  Validators.required(v, context.l10n.staffInviteNameLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaPhoneField(
              controller: _phoneCtrl,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'staff',
                  label: Text(context.l10n.staffInviteRoleStaff),
                ),
                if (canAssignManager)
                  ButtonSegment(
                    value: 'manager',
                    label: Text(context.l10n.staffInviteRoleManager),
                  ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: AppSpacing.xxl),
            KynzaButton(
              label: context.l10n.staffInviteSubmitButton,
              isLoading: _isSending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
