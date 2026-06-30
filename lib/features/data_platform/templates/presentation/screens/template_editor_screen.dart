import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../../core/models/document_template_model.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/template_providers.dart';

const _types = ['invoice', 'receipt', 'monthly_report'];

// Variable hints shown to the user per template type.
const _variableHints = {
  'invoice':
      '{{client_name}}, {{service_name}}, {{price}}, {{date}}, {{salon_name}}, {{booking_id}}, {{staff_name}}',
  'receipt':
      '{{client_name}}, {{service_name}}, {{price}}, {{date}}, {{salon_name}}, {{payment_method}}, {{amount_paid}}',
  'monthly_report':
      '{{month}}, {{total_revenue}}, {{bookings_completed}}, {{top_service}}, {{salon_name}}, {{no_show_rate}}',
};

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
  'invoice' => l10n.dataPlatformTemplateTypeInvoice,
  'receipt' => l10n.dataPlatformTemplateTypeReceipt,
  'monthly_report' => l10n.dataPlatformTemplateTypeMonthlyReport,
  _ => type,
};

class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({
    super.key,
    required this.salonId,
    this.existing,
  });

  final String salonId;
  final DocumentTemplateModel? existing;

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'invoice';
  bool _isDefault = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _nameController.text = t.name;
      _bodyController.text = t.body;
      _type = t.type;
      _isDefault = t.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      showKynzaToast(
        context,
        message: context.l10n.dataPlatformTemplateValidationError,
        level: ToastLevel.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(templateNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateTemplate(
          id: widget.existing!.id,
          salonId: widget.salonId,
          type: _type,
          name: _nameController.text.trim(),
          body: _bodyController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await notifier.createTemplate(
          salonId: widget.salonId,
          type: _type,
          name: _nameController.text.trim(),
          body: _bodyController.text.trim(),
          isDefault: _isDefault,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showKynzaToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        level: ToastLevel.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hints = _variableHints[_type] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.dataPlatformTemplateEditTitle
              : l10n.dataPlatformTemplateNewTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KynzaTextField(
            label: l10n.dataPlatformTemplateNameLabel,
            controller: _nameController,
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaDropdown<String>(
            label: l10n.dataPlatformTemplateTypeLabel,
            value: _type,
            items: _types,
            itemLabel: (t) => _typeLabel(l10n, t),
            onChanged: (v) => setState(() => _type = v ?? 'invoice'),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dataPlatformTemplateVariablesTitle,
                    style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hints,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaTextField(
            label: l10n.dataPlatformTemplateBodyLabel,
            controller: _bodyController,
            maxLines: 14,
            hint: l10n.dataPlatformTemplateBodyHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Switch(
                value: _isDefault,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.dataPlatformTemplateIsDefaultLabel,
                  style: AppTypography.body),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: _isEditing
                ? l10n.dataPlatformTemplateSaveButton
                : l10n.dataPlatformTemplateCreateButton,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
