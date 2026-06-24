import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/presentation/screens/booking_confirmation_screen.dart';
import '../widgets/radar_pulse_widget.dart';

enum _PaymentPhase { selectMethod, waiting, success, failed }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'lumicash';
  final _phoneCtrl = TextEditingController();
  _PaymentPhase _phase = _PaymentPhase.selectMethod;
  int _secondsRemaining = 180;
  Timer? _countdownTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingSub;
  bool _isInitiating = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _countdownTimer?.cancel();
    _bookingSub?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    if (Validators.phone(_phoneCtrl.text) != null) {
      showKynzaToast(
        context,
        message: 'Numéro invalide.',
        level: ToastLevel.warning,
      );
      return;
    }
    setState(() => _isInitiating = true);
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-payment',
        body: {
          'bookingId': widget.booking.id,
          'method': _method,
          'phone': _phoneCtrl.text.trim(),
        },
      );
      if (res.status != 200) {
        throw Exception('initiation_failed');
      }
      setState(() {
        _phase = _PaymentPhase.waiting;
        _isInitiating = false;
        _secondsRemaining = 180;
      });
      _startCountdown();
      _watchBookingStatus();
    } catch (_) {
      setState(() {
        _isInitiating = false;
        _phase = _PaymentPhase.failed;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted && _phase == _PaymentPhase.waiting) {
          setState(() => _phase = _PaymentPhase.failed);
        }
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _watchBookingStatus() {
    final client = ref.read(supabaseClientProvider);
    _bookingSub = client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', widget.booking.id as Object)
        .listen((rows) {
          if (rows.isEmpty || !mounted) return;
          final status = rows.first['status'] as String?;
          if (status == 'confirmed') {
            _countdownTimer?.cancel();
            setState(() => _phase = _PaymentPhase.success);
            Future.delayed(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      BookingConfirmationScreen(booking: widget.booking),
                ),
              );
            });
          } else if (status == 'cancelled') {
            _countdownTimer?.cancel();
            setState(() => _phase = _PaymentPhase.failed);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: _buildPhase()),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _PaymentPhase.waiting:
      case _PaymentPhase.success:
        return RadarPulseWidget(secondsRemaining: _secondsRemaining);
      case _PaymentPhase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              "Ce paiement n'a pas abouti. Aucun argent débité.",
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(
              label: 'Réessayer',
              onPressed: () =>
                  setState(() => _phase = _PaymentPhase.selectMethod),
            ),
          ],
        );
      case _PaymentPhase.selectMethod:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Méthode de paiement', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Lumicash'),
                    selected: _method == 'lumicash',
                    onSelected: (_) => setState(() => _method = 'lumicash'),
                  ),
                  ChoiceChip(
                    label: const Text('EcoCash'),
                    selected: _method == 'ecocash',
                    onSelected: (_) => setState(() => _method = 'ecocash'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              KynzaPhoneField(
                controller: _phoneCtrl,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: KynzaAmountWidget(
                  amountBif: widget.booking.amountBif,
                  style: AppTypography.amount,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: const Text(
                  'Vous allez recevoir une demande USSD sur votre téléphone. '
                  'Entrez votre code PIN pour confirmer.',
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: 'Payer →',
                isLoading: _isInitiating,
                onPressed: _pay,
              ),
            ],
          ),
        );
    }
  }
}
