import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../../staff/application/providers/staff_providers.dart';
import '../../application/providers/booking_providers.dart';

/// Owner Dashboard "+ Nouveau RDV" — the client has no KYNZA account, so
/// only first name + phone are collected; a guest user is provisioned
/// server-side by create-walkin-booking.
class WalkInBookingSheet extends ConsumerStatefulWidget {
  const WalkInBookingSheet({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<WalkInBookingSheet> createState() => _WalkInBookingSheetState();
}

class _WalkInBookingSheetState extends ConsumerState<WalkInBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  ServiceModel? _service;
  StaffProfileModel? _practitioner;
  TimeOfDay _time = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_service == null || _practitioner == null) {
      showKynzaToast(
        context,
        message: 'Service et praticien requis.',
        level: ToastLevel.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    try {
      await ref
          .read(bookingActionNotifierProvider.notifier)
          .createWalkIn(
            salonId: widget.salonId,
            serviceId: _service!.id!,
            practitionerId: _practitioner!.id!,
            startTime: startTime,
            guestFirstName: _nameCtrl.text.trim(),
            guestPhone: '+257${_phoneCtrl.text.trim()}',
          );
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
    final servicesAsync = ref.watch(salonServicesProvider(widget.salonId));
    final staffAsync = ref.watch(salonStaffProvider(widget.salonId));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouveau RDV', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            KynzaTextField(
              label: 'Prénom du client *',
              controller: _nameCtrl,
              validator: (v) => Validators.required(v, 'Prénom'),
            ),
            const SizedBox(height: AppSpacing.md),
            KynzaPhoneField(
              controller: _phoneCtrl,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            servicesAsync.when(
              loading: () => const KynzaSkeleton(height: 52),
              error: (_, __) =>
                  const Text('Impossible de charger les services.'),
              data: (services) {
                final active = services.where((s) => s.isActive).toList();
                return KynzaDropdown<ServiceModel>(
                  label: 'Service *',
                  value: _service,
                  items: active,
                  itemLabel: (s) => '${s.name} (${s.formattedDuration})',
                  onChanged: (v) => setState(() => _service = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            staffAsync.when(
              loading: () => const KynzaSkeleton(height: 52),
              error: (_, __) => const Text("Impossible de charger l'équipe."),
              data: (staff) {
                final active = staff
                    .where((s) => s.isActive && !s.isPending)
                    .toList();
                return KynzaDropdown<StaffProfileModel>(
                  label: 'Praticien *',
                  value: _practitioner,
                  items: active,
                  itemLabel: (s) => s.displayName,
                  onChanged: (v) => setState(() => _practitioner = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Heure'),
              trailing: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                style: AppTypography.mono,
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: 'Créer le RDV',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
