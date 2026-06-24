import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/service_model.dart';
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
              .markStep(widget.salonId, 'first_service'),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : 'Une erreur est survenue.',
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
        title: Text(_isEditing ? 'Modifier le service' : 'Nouveau service'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            KynzaTextField(
              label: 'Nom du service *',
              controller: _nameCtrl,
              validator: (v) => Validators.required(v, 'Nom du service'),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaDropdown<String>(
              label: 'Catégorie *',
              value: _category,
              items: ServiceCategories.all,
              itemLabel: (c) => c,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Description',
              controller: _descriptionCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Durée (minutes) *',
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n <= 0) ? 'Durée invalide.' : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Temps de préparation (minutes)',
              controller: _bufferCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Prix (FBu) *',
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0) ? 'Prix invalide.' : null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            KynzaAmountWidget(amountBif: previewPrice),
            const SizedBox(height: AppSpacing.xxl),
            KynzaButton(
              label: 'Enregistrer',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
