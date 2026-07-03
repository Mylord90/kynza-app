import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../journey/application/providers/journey_providers.dart';
import '../../application/providers/service_providers.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({super.key, required this.salonId, this.existing});

  final String salonId;
  final ServiceModel? existing;

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _descriptionCtrl = TextEditingController(
    text: widget.existing?.description,
  );
  late final _durationCtrl = TextEditingController(
    text: widget.existing?.durationMin.toString(),
  );
  late final _bufferCtrl = TextEditingController(
    text: widget.existing?.bufferMin.toString() ?? '0',
  );
  late final _priceCtrl = TextEditingController(
    text: widget.existing?.priceBif.toString(),
  );
  String? _category;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? ServiceCategories.all.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    _bufferCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final service = ServiceModel(
      id: widget.existing?.id,
      salonId: widget.salonId,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      category: _category!,
      durationMin: int.parse(_durationCtrl.text),
      bufferMin: int.tryParse(_bufferCtrl.text) ?? 0,
      priceBif: int.parse(_priceCtrl.text),
      isActive: widget.existing?.isActive ?? true,
    );

    try {
      final notifier = ref.read(serviceNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateService(service);
      } else {
        await notifier.create(service);
        unawaited(
          ref
              .read(journeyNotifierProvider.notifier)
              .markStep(widget.salonId, 'first_service')
              .catchError(CrashReportingService.recordError),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : context.l10n.errorGeneric,
          level: ToastLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewPrice = int.tryParse(_priceCtrl.text) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? context.l10n.servicesFormEditTitle
              : context.l10n.servicesFormNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            KynzaTextField(
              label: context.l10n.servicesFormNameLabel,
              controller: _nameCtrl,
              validator: (v) =>
                  Validators.required(v, context.l10n.servicesFormNameLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaDropdown<String>(
              label: context.l10n.servicesFormCategoryLabel,
              value: _category,
              items: ServiceCategories.all,
              itemLabel: (c) => c,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.servicesFormDescriptionLabel,
              controller: _descriptionCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.servicesFormDurationLabel,
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n <= 0)
                    ? context.l10n.servicesFormDurationError
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.servicesFormBufferLabel,
              controller: _bufferCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: context.l10n.servicesFormPriceLabel,
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0)
                    ? context.l10n.servicesFormPriceError
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            KynzaAmountWidget(amountBif: previewPrice),
            const SizedBox(height: AppSpacing.xxl),
            KynzaButton(
              label: context.l10n.commonSave,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
