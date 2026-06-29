import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
        message: 'Impossible de créer ce groupe.',
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
            const Text(
              'Nouveau groupe de permissions',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Nom du groupe',
              hint: 'ex. Réceptionniste Senior',
              controller: _nameController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaTextField(
              label: 'Description (optionnel)',
              controller: _descriptionController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaDropdown<String>(
              label: 'Rôle de base',
              value: _baseRole,
              items: _baseRoles,
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => _baseRole = v ?? 'staff'),
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: 'Créer le groupe',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
