import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/currency_display_service.dart';

class KynzaAmountWidget extends ConsumerWidget {
  const KynzaAmountWidget({
    super.key,
    required this.amountBif,
    this.style,
    this.confidential = false,
  });

  final int amountBif;
  final TextStyle? style;
  final bool confidential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalConfidential = ref.watch(confidentialModeProvider);
    final text = CurrencyDisplayService.instance.display(
      amountBif,
      confidential: confidential || globalConfidential,
    );
    return Text(text, style: style ?? AppTypography.amount);
  }
}
