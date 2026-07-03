import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/salon_media_model.dart';
import '../../../../core/models/working_hour_model.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../journey/application/providers/journey_providers.dart';
import '../../application/providers/salon_providers.dart';
import '../widgets/media_grid_widget.dart' show kMaxPortfolioItems;
import 'salon_creation_success_screen.dart';
import 'salon_hours_step.dart';
import 'salon_info_step.dart';
import 'salon_location_step.dart';
import 'salon_media_step.dart';

class SalonCreationWizardScreen extends ConsumerStatefulWidget {
  const SalonCreationWizardScreen({super.key});

  @override
  ConsumerState<SalonCreationWizardScreen> createState() =>
      _SalonCreationWizardScreenState();
}

class _SalonCreationWizardScreenState
    extends ConsumerState<SalonCreationWizardScreen> {
  static const _totalSteps = 4;

  int _step = 1;
  bool _isSubmitting = false;
  String? _submitError;

  final _formKeys = List.generate(2, (_) => GlobalKey<FormState>());

  final _nameCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _province;
  String? _commune;

  late List<WorkingHourModel> _hours = List.generate(
    7,
    (day) => WorkingHourModel(
      salonId: '',
      dayOfWeek: day,
      isClosed: day == 6,
      opensAt: '08:00:00',
      closesAt: '18:00:00',
    ),
  );

  Uint8List? _logoBytes;
  String? _logoExt;
  Uint8List? _coverBytes;
  String? _coverExt;
  final List<PortfolioDraft> _portfolio = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sloganCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step <= _formKeys.length &&
        !_formKeys[_step - 1].currentState!.validate()) {
      return;
    }
    if (_step < _totalSteps) setState(() => _step++);
  }

  void _back() {
    if (_step > 1) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final draft = SalonFullModel(
      id: '',
      name: _nameCtrl.text.trim(),
      slogan: _sloganCtrl.text.trim().isEmpty ? null : _sloganCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      province: _province,
      commune: _commune,
      socialFacebook: _facebookCtrl.text.trim().isEmpty
          ? null
          : _facebookCtrl.text.trim(),
      socialInstagram: _instagramCtrl.text.trim().isEmpty
          ? null
          : _instagramCtrl.text.trim(),
      socialTiktok: _tiktokCtrl.text.trim().isEmpty
          ? null
          : _tiktokCtrl.text.trim(),
      socialWhatsapp: _whatsappCtrl.text.trim().isEmpty
          ? null
          : _whatsappCtrl.text.trim(),
    );

    try {
      final notifier = ref.read(salonNotifierProvider.notifier);
      final created = await notifier.create(draft);

      if (_logoBytes != null) {
        await notifier.uploadLogo(_logoBytes!, _logoExt!);
      }
      if (_coverBytes != null) {
        await notifier.uploadCover(_coverBytes!, _coverExt!);
      }
      for (final p in _portfolio) {
        await notifier.uploadMedia(p.$1, p.$2, p.$3);
      }
      await notifier.updateWorkingHours([
        for (final h in _hours) h.copyWith(salonId: created.id),
      ]);

      // The wizard collects salon info and working hours together, so
      // both journey steps complete at the same moment — best-effort,
      // a failed markStep must never block the salon from being created.
      unawaited(
        ref
            .read(journeyNotifierProvider.notifier)
            .markStep(created.id, 'salon_info')
            .catchError(CrashReportingService.recordError),
      );
      unawaited(
        ref
            .read(journeyNotifierProvider.notifier)
            .markStep(created.id, 'hours')
            .catchError(CrashReportingService.recordError),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SalonCreationSuccessScreen()),
      );
    } catch (e) {
      setState(() {
        _submitError = e is AppException
            ? e.message
            : context.l10n.salonCreationErrorGeneric;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.salonCreationTitle)),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          _StepDots(current: _step, total: _totalSteps),
          const SizedBox(height: AppSpacing.md),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _submitError!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.standard,
              child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (_step > 1)
                  Expanded(
                    child: KynzaButton(
                      label: context.l10n.commonBack,
                      variant: KynzaButtonVariant.ghost,
                      onPressed: _isSubmitting ? null : _back,
                    ),
                  ),
                if (_step > 1) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: KynzaButton(
                    label: _step == _totalSteps
                        ? context.l10n.salonCreationSubmitButton
                        : context.l10n.salonCreationNextButton,
                    isLoading: _isSubmitting,
                    onPressed: _step == _totalSteps ? _submit : _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return SalonInfoStep(
          formKey: _formKeys[0],
          nameController: _nameCtrl,
          sloganController: _sloganCtrl,
          descriptionController: _descriptionCtrl,
          phoneController: _phoneCtrl,
          emailController: _emailCtrl,
          facebookController: _facebookCtrl,
          instagramController: _instagramCtrl,
          tiktokController: _tiktokCtrl,
          whatsappController: _whatsappCtrl,
        );
      case 2:
        return SalonLocationStep(
          formKey: _formKeys[1],
          addressController: _addressCtrl,
          province: _province,
          commune: _commune,
          onProvinceChanged: (v) => setState(() => _province = v),
          onCommuneChanged: (v) => setState(() => _commune = v),
        );
      case 3:
        return SalonHoursStep(
          hours: _hours,
          onChanged: (h) => setState(() => _hours = h),
        );
      default:
        return SalonMediaStep(
          logoBytes: _logoBytes,
          coverBytes: _coverBytes,
          portfolio: _portfolio,
          onLogoPicked: (bytes, ext) => setState(() {
            _logoBytes = bytes;
            _logoExt = ext;
          }),
          onCoverPicked: (bytes, ext) => setState(() {
            _coverBytes = bytes;
            _coverExt = ext;
          }),
          onPortfolioAdded: (bytes, ext) => setState(() {
            if (_portfolio.length < kMaxPortfolioItems) {
              _portfolio.add((bytes, ext, MediaType.image));
            }
          }),
          onPortfolioRemoved: (index) =>
              setState(() => _portfolio.removeAt(index)),
        );
    }
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i < current;
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
