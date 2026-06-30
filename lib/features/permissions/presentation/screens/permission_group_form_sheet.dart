import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/permission_management_providers.dart';

const _baseRoles = ['manager', 'staff', 'client'];

class PermissionGroupFormSheet extends ConsumerStatefulWidget {
  const PermissionGroupFormSheet({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<PermissionGroupFormSheet> createState() =>
      _PermissionGroupFormSheetState();
}

class _PermissionGroupFormSheetState
    extends ConsumerState<PermissionGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _baseRole = 'staff';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final group = await ref
          .read(permissionGroupNotifierProvider.notifier)
          .createGroup(
            salonId: widget.salonId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            baseRole: _baseRole,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.push(RouteNames.ownerPermissionGroupDetailPath(group.id));
    } catch (_) {
      if (!mounted) return;
      showKynzaToast(
        context,
        message: context.l10n.permissionsGroupCreateError,
        level: ToastLevel.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.permissionsGroupFormTitle,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.permissionsGroupFormNameLabel,
              hint: context.l10n.permissionsGroupNameHint,
              controller: _nameController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.l10n.permissionsGroupFormNameRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaTextField(
              label: context.l10n.permissionsGroupFormDescriptionLabel,
              controller: _descriptionController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaDropdown<String>(
              label: context.l10n.permissionsGroupFormBaseRoleLabel,
              value: _baseRole,
              items: _baseRoles,
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => _baseRole = v ?? 'staff'),
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: context.l10n.permissionsGroupFormCreateButton,
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
