import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
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
      await Share.share(
        "Vous êtes invité(e) à rejoindre l'équipe sur KYNZA ! "
        'Code invitation : ${staff.invitationToken}',
        subject: 'Invitation KYNZA',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : "Échec de l'invitation.",
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
      appBar: AppBar(title: const Text('Inviter un membre')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            KynzaTextField(
              label: 'Nom *',
              controller: _nameCtrl,
              validator: (v) => Validators.required(v, 'Nom'),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaPhoneField(
              controller: _phoneCtrl,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'staff', label: Text('Staff')),
                if (canAssignManager)
                  const ButtonSegment(value: 'manager', label: Text('Manager')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: AppSpacing.xxl),
            KynzaButton(
              label: "Envoyer l'invitation",
              isLoading: _isSending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
