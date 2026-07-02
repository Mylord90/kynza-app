import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/proxipay/proxipay_session_model.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/proxipay_providers.dart';

enum _ScanStage { scanning, confirming, submitting, success, error }

/// Client scans the staff's ProxiPay QR (raw `proxipay_sessions.id`) and
/// pays in-app. The staff device never sees the phone number entered here —
/// it goes straight to proxipay-confirm (see [ProxiPayRepository]).
class ProxiPayScanScreen extends ConsumerStatefulWidget {
  const ProxiPayScanScreen({super.key});

  @override
  ConsumerState<ProxiPayScanScreen> createState() => _ProxiPayScanScreenState();
}

class _ProxiPayScanScreenState extends ConsumerState<ProxiPayScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _phoneCtrl = TextEditingController();
  final _debugSessionCtrl = TextEditingController();
  _ScanStage _stage = _ScanStage.scanning;
  ProxiPaySessionModel? _session;
  String _method = 'lumicash';
  String? _errorMessage;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _phoneCtrl.dispose();
    _debugSessionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _stage != _ScanStage.scanning) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _resolveSession(raw);
  }

  /// Single-device QA affordance: with only one emulator, there's no second
  /// phone to physically scan the staff's QR. This bypasses the camera and
  /// resolves a session id typed/pasted in directly — same code path as a
  /// real scan from here on. Debug builds only, never in release.
  Future<void> _resolveSession(String raw) async {
    final invalidMsg = context.l10n.proxipayScanInvalidError;
    final connectionMsg = context.l10n.proxipayScanConnectionError;

    setState(() => _busy = true);
    try {
      final session = await ref
          .read(proxipayNotifierProvider.notifier)
          .getSession(raw);
      if (!mounted) return;
      if (session == null || !session.isPending) {
        KynzaHaptics.error();
        setState(() {
          _busy = false;
          _errorMessage = invalidMsg;
        });
        return;
      }
      KynzaHaptics.success();
      setState(() {
        _session = session;
        _stage = _ScanStage.confirming;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = connectionMsg;
      });
    }
  }

  Future<void> _confirm() async {
    final session = _session;
    if (session == null) return;
    if (Validators.phone(_phoneCtrl.text) != null) {
      showKynzaToast(
        context,
        message: context.l10n.paymentInvalidPhone,
        level: ToastLevel.warning,
      );
      return;
    }
    setState(() => _stage = _ScanStage.submitting);
    try {
      await ref
          .read(proxipayNotifierProvider.notifier)
          .confirmSession(
            sessionId: session.id,
            method: _method,
            phone: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      KynzaHaptics.success();
      setState(() => _stage = _ScanStage.success);
    } catch (e) {
      if (!mounted) return;
      KynzaHaptics.error();
      setState(() {
        _stage = _ScanStage.confirming;
        _errorMessage = context.l10n.proxipayConfirmErrorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.proxipayScanTitle)),
      body: switch (_stage) {
        _ScanStage.scanning => _buildScanner(),
        _ScanStage.confirming || _ScanStage.submitting => _buildConfirmForm(),
        _ScanStage.success => _buildSuccess(),
        _ScanStage.error => _buildScanner(),
      },
    );
  }

  Widget _buildScanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xl,
          child: Text(
            context.l10n.proxipayScanInstruction,
            style: AppTypography.body.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: KynzaOfflineBanner(),
        ),
        if (kDebugMode) _buildDebugSessionEntry(),
        if (_errorMessage != null)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugSessionEntry() {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _debugSessionCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'DEBUG: session id',
                  hintStyle: TextStyle(color: Colors.white54),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      final raw = _debugSessionCtrl.text.trim();
                      if (raw.isEmpty) return;
                      _resolveSession(raw);
                    },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmForm() {
    final session = _session!;
    final salonAsync = ref.watch(salonByIdProvider(session.salonId));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (salonAsync.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                salonAsync.valueOrNull!.name,
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
            ),
          Center(
            child: KynzaAmountWidget(
              amountBif: session.amountBif,
              style: AppTypography.amount,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.paymentMethodTitle, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text(context.l10n.paymentMethodLumicash),
                selected: _method == 'lumicash',
                onSelected: (_) => setState(() => _method = 'lumicash'),
              ),
              ChoiceChip(
                label: Text(context.l10n.paymentMethodEcocash),
                selected: _method == 'ecocash',
                onSelected: (_) => setState(() => _method = 'ecocash'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          KynzaPhoneField(controller: _phoneCtrl, validator: Validators.phone),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: context.l10n.proxipayConfirmPayButton,
            isLoading: _stage == _ScanStage.submitting,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.proxipayConfirmSuccessMessage,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: context.l10n.proxipayDoneButton,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
