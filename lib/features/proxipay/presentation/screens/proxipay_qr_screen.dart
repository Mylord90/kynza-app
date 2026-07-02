import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/proxipay/proxipay_session_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../application/providers/proxipay_providers.dart';

enum _ProxiPayPhase {
  creating,
  awaitingScan,
  awaitingSettlement,
  success,
  failed,
  expired,
}

/// Staff-facing screen reached from "Terminer & encaisser" — generates a
/// short-lived [ProxiPaySessionModel], displays it as a QR the client scans
/// in-app, then waits for the client to confirm and pay before finally
/// marking the booking completed. The client's Mobile Money number never
/// reaches this screen — see [ProxiPayRepository.confirmSession].
class ProxiPayQrScreen extends ConsumerStatefulWidget {
  const ProxiPayQrScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  ConsumerState<ProxiPayQrScreen> createState() => _ProxiPayQrScreenState();
}

class _ProxiPayQrScreenState extends ConsumerState<ProxiPayQrScreen> {
  ProxiPaySessionModel? _session;
  _ProxiPayPhase _phase = _ProxiPayPhase.creating;
  Duration _remaining = Duration.zero;
  Timer? _ticker;
  StreamSubscription<ProxiPaySessionModel?>? _sessionSub;
  StreamSubscription<List<Map<String, dynamic>>>? _transactionSub;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sessionSub?.cancel();
    _transactionSub?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    _ticker?.cancel();
    _sessionSub?.cancel();
    _transactionSub?.cancel();
    setState(() {
      _phase = _ProxiPayPhase.creating;
      _error = null;
    });
    try {
      final session = await ref
          .read(proxipayNotifierProvider.notifier)
          .createSession(widget.booking.id!);
      if (!mounted) return;
      setState(() {
        _session = session;
        _phase = _ProxiPayPhase.awaitingScan;
        _remaining = session.expiresAt.difference(DateTime.now());
      });
      _startTicker();
      _watchSession(session.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.proxipayCreateSessionError;
        _phase = _ProxiPayPhase.failed;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _session;
      if (session == null ||
          !mounted ||
          _phase != _ProxiPayPhase.awaitingScan) {
        return;
      }
      final remaining = session.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _ticker?.cancel();
        setState(() => _phase = _ProxiPayPhase.expired);
        return;
      }
      setState(() => _remaining = remaining);
    });
  }

  void _watchSession(String sessionId) {
    _sessionSub = ref
        .read(proxipayRepositoryProvider)
        .watchSession(sessionId)
        .listen((session) {
          if (session == null || !mounted) return;
          if (session.isConfirmed && _phase == _ProxiPayPhase.awaitingScan) {
            _ticker?.cancel();
            setState(() => _phase = _ProxiPayPhase.awaitingSettlement);
            _watchTransaction();
          }
        });
  }

  void _watchTransaction() {
    final client = ref.read(supabaseClientProvider);
    _transactionSub = client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('booking_id', widget.booking.id as Object)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((rows) async {
          if (rows.isEmpty || !mounted) return;
          final status = rows.first['status'] as String?;
          if (status == 'completed' || status == 'processing') {
            _transactionSub?.cancel();
            try {
              await ref
                  .read(bookingActionNotifierProvider.notifier)
                  .markCompleted(widget.booking);
            } catch (_) {
              // Booking completion is best-effort here — the payment itself
              // already succeeded; staff can still tap "Terminer" manually.
            }
            if (!mounted) return;
            setState(() => _phase = _ProxiPayPhase.success);
          } else if (status == 'failed') {
            _transactionSub?.cancel();
            if (!mounted) return;
            setState(() => _phase = _ProxiPayPhase.failed);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.proxipayQrTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _buildPhase(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _ProxiPayPhase.creating:
        return const KynzaLoader(size: KynzaLoaderSize.medium);

      case _ProxiPayPhase.awaitingScan:
        final session = _session!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KynzaAmountWidget(
              amountBif: session.amountBif,
              style: AppTypography.amount,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: QrImageView(
                data: session.id,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _formatRemaining(_remaining, context),
              style: AppTypography.h3.copyWith(
                color: _remaining.inSeconds <= 30
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.proxipayQrShowToClient,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ProxiPayPhase.awaitingSettlement:
        return RadarPulseWidget(
          secondsRemaining: 60,
          message: context.l10n.proxipayAwaitingSettlementMessage,
        );

      case _ProxiPayPhase.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.proxipaySuccessMessage,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: context.l10n.proxipayDoneButton,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );

      case _ProxiPayPhase.expired:
      case _ProxiPayPhase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _phase == _ProxiPayPhase.expired
                  ? context.l10n.proxipayQrExpired
                  : (_error ?? context.l10n.proxipayFailedMessage),
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: context.l10n.proxipayRetryButton,
              onPressed: _generate,
            ),
          ],
        );
    }
  }
}

String _formatRemaining(Duration d, BuildContext context) {
  final clamped = d.isNegative ? Duration.zero : d;
  final minutes = clamped.inMinutes.toString().padLeft(2, '0');
  final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
  return context.l10n.proxipayQrExpiresIn(minutes, seconds);
}
