import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

enum _ScanResultKind { success, error }

class _ScanResult {
  const _ScanResult(this.kind, this.message);
  final _ScanResultKind kind;
  final String message;
}

/// Staff/owner/manager scans a client's loyalty QR (see [LoyaltyQrScreen])
/// — validate-qr Edge Function decides server-side whether this adds a
/// stamp or redeems the reward, this screen only shows the outcome.
class LoyaltyScanScreen extends StatefulWidget {
  const LoyaltyScanScreen({super.key});

  @override
  State<LoyaltyScanScreen> createState() => _LoyaltyScanScreenState();
}

class _LoyaltyScanScreenState extends State<LoyaltyScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;
  _ScanResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _busy = true);
    try {
      final res = await SupabaseService.client.functions.invoke(
        'validate-qr',
        body: {'token': raw},
      );
      final data = res.data is Map ? res.data as Map : null;
      if (res.status != 200 || data?['success'] != true) {
        _showResult(
          _ScanResult(
            _ScanResultKind.error,
            data?['message'] as String? ?? 'QR invalide ou expiré.',
          ),
        );
        return;
      }
      final action = data?['action'];
      final clientName = data?['clientName'] as String? ?? '';
      final name = clientName.isEmpty ? '' : ' — $clientName';
      _showResult(
        _ScanResult(
          _ScanResultKind.success,
          action == 'redeemed'
              ? '✅ Récompense validée !$name'
              : '✅ Tampon ajouté !$name',
        ),
      );
    } catch (_) {
      _showResult(
        const _ScanResult(
          _ScanResultKind.error,
          'Connexion impossible. Réessayez.',
        ),
      );
    }
  }

  void _showResult(_ScanResult result) {
    if (!mounted) return;
    if (result.kind == _ScanResultKind.success) {
      KynzaHaptics.success();
    } else {
      KynzaHaptics.error();
    }
    setState(() {
      _result = result;
      _busy = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _result = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Scanner fidélité')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScanFrame(),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: KynzaOfflineBanner(),
          ),
          if (_result != null) _ResultOverlay(result: _result!),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.result});

  final _ScanResult result;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.kind == _ScanResultKind.success;
    return Container(
      color: (isSuccess ? AppColors.success : AppColors.error).withValues(
        alpha: 0.92,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 72,
              color: Colors.white,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              result.message,
              style: AppTypography.h2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
