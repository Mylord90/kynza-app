import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../../team/application/providers/commission_providers.dart';
import '../../application/providers/staff_providers.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  const StaffFormScreen({super.key, required this.staff});

  final StaffProfileModel staff;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  late final _nameCtrl = TextEditingController(text: widget.staff.displayName);
  late final _bioCtrl = TextEditingController(text: widget.staff.bio);
  late final _phoneCtrl = TextEditingController(text: widget.staff.phone);
  late final _commissionRateCtrl = TextEditingController(
    text: widget.staff.commissionRate == 0
        ? ''
        : widget.staff.commissionRate.toString(),
  );
  late String _commissionType = widget.staff.commissionType;
  bool _isSaving = false;
  Set<String> _assignedServiceIds = {};

  @override
  void initState() {
    super.initState();
    ref
        .read(staffRepositoryProvider)
        .getAssignedServiceIds(widget.staff.id!)
        .then((ids) {
          if (mounted) setState(() => _assignedServiceIds = ids.toSet());
        });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _commissionRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(staffNotifierProvider.notifier)
          .updateStaff(
            widget.staff.copyWith(
              displayName: _nameCtrl.text.trim(),
              bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
            ),
          );
      await ref
          .read(commissionNotifierProvider.notifier)
          .updateRate(
            widget.staff.id!,
            _commissionType,
            num.tryParse(_commissionRateCtrl.text.trim()) ?? 0,
          );
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

  Future<void> _remove() async {
    final confirmed = await showKynzaConfirmDialog(
      context,
      title: context.l10n.staffFormRemoveConfirmTitle,
      message: context.l10n.staffFormRemoveConfirmMessage(
        widget.staff.displayName,
      ),
    );
    if (!confirmed) return;
    try {
      await ref.read(staffNotifierProvider.notifier).remove(widget.staff.id!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showKynzaToast(
          context,
          message: e is AppException ? e.message : context.l10n.errorGeneric,
          level: ToastLevel.error,
        );
      }
    }
  }

  void _toggleService(String serviceId, bool assigned) {
    setState(() {
      if (assigned) {
        _assignedServiceIds.add(serviceId);
      } else {
        _assignedServiceIds.remove(serviceId);
      }
    });
    final notifier = ref.read(staffNotifierProvider.notifier);
    if (assigned) {
      notifier
          .assignService(widget.staff.id!, serviceId, widget.staff.salonId)
          .catchError((_) {});
    } else {
      notifier.removeService(widget.staff.id!, serviceId).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(
      salonServicesProvider(widget.staff.salonId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.staffFormTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          KynzaTextField(
            label: context.l10n.staffFormDisplayNameLabel,
            controller: _nameCtrl,
          ),
          const SizedBox(height: AppSpacing.lg),
          KynzaTextField(
            label: context.l10n.staffFormPhoneLabel,
            controller: _phoneCtrl,
          ),
          const SizedBox(height: AppSpacing.lg),
          KynzaTextField(
            label: context.l10n.staffFormBioLabel,
            controller: _bioCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.staffFormCommissionSectionTitle,
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KynzaDropdown<String>(
                  label: context.l10n.staffFormCommissionTypeLabel,
                  value: _commissionType,
                  items: const ['percent', 'fixed'],
                  itemLabel: (v) => v == 'percent'
                      ? context.l10n.staffFormCommissionTypePercent
                      : context.l10n.staffFormCommissionTypeFixed,
                  onChanged: (v) =>
                      setState(() => _commissionType = v ?? 'percent'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: KynzaTextField(
                  label: _commissionType == 'percent'
                      ? context.l10n.staffFormCommissionRatePercent
                      : context.l10n.staffFormCommissionRateFixed,
                  controller: _commissionRateCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.staffDetailServicesTitle, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          servicesAsync.when(
            loading: () => const KynzaSkeleton(height: 120),
            error: (_, __) => Text(context.l10n.staffFormServicesLoadError),
            data: (services) => Column(
              children: [
                for (final s in services)
                  CheckboxListTile(
                    title: Text(s.name),
                    value: _assignedServiceIds.contains(s.id),
                    activeColor: AppColors.primary,
                    onChanged: (v) => _toggleService(s.id!, v ?? false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          KynzaButton(
            label: context.l10n.staffFormSaveButton,
            isLoading: _isSaving,
            onPressed: _save,
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaButton(
            label: context.l10n.staffFormRemoveButton,
            variant: KynzaButtonVariant.destructive,
            onPressed: _remove,
          ),
        ],
      ),
    );
  }
}
