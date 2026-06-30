import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/loyalty/loyalty_card_model.dart';
import '../../../../core/models/loyalty/loyalty_qr_token_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/loyalty_providers.dart';

/// Shown by a client to staff (see [LoyaltyScanScreen]) so a visit can be
/// validated without either side typing anything — the QR payload is just
/// the loyalty_qr_tokens row id, single-use and short-lived (10 min).
class LoyaltyQrScreen extends ConsumerStatefulWidget {
  const LoyaltyQrScreen({super.key, required this.cardId});

  final String cardId;

  @override
  ConsumerState<LoyaltyQrScreen> createState() => _LoyaltyQrScreenState();
}

class _LoyaltyQrScreenState extends ConsumerState<LoyaltyQrScreen> {
  LoyaltyQrTokenModel? _token;
  String? _error;
  bool _loading = true;
  Duration _remaining = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  LoyaltyCardModel? _findCard() {
    final cards = ref.read(clientLoyaltyCardsProvider).valueOrNull ?? [];
    for (final card in cards) {
      if (card.id == widget.cardId) return card;
    }
    return null;
  }

  Future<void> _generate() async {
    final card = _findCard();
    if (card == null) {
      final msg = context.l10n.loyaltyQrCardNotFound;
      setState(() {
        _error = msg;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref
          .read(loyaltyNotifierProvider.notifier)
          .createQrToken(card);
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
        _remaining = token.expiresAt.difference(DateTime.now());
      });
      _startTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.loyaltyQrGenerateError;
        _loading = false;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final token = _token;
      if (token == null || !mounted) return;
      final remaining = token.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _generate();
        return;
      }
      setState(() => _remaining = remaining);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _findCard();
    final salonAsync = card == null
        ? null
        : ref.watch(salonByIdProvider(card.salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.loyaltyQrTitle)),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _loading
                    ? const KynzaSpinner()
                    : _error != null
                    ? KynzaErrorState(message: _error!, onRetry: _generate)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (salonAsync?.valueOrNull != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              child: Text(
                                salonAsync!.valueOrNull!.name,
                                style: AppTypography.h2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: _token!.id,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            _formatRemaining(_remaining, context),
                            style: AppTypography.h3.copyWith(
                              color: _remaining.inSeconds <= 120
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.l10n.loyaltyQrShowToStaff,
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration d, BuildContext context) {
  final clamped = d.isNegative ? Duration.zero : d;
  final minutes = clamped.inMinutes.toString().padLeft(2, '0');
  final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
  return context.l10n.loyaltyQrExpiresIn(minutes, seconds);
}
