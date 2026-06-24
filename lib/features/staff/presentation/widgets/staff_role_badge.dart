import 'package:flutter/material.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class StaffRoleBadge extends StatelessWidget {
  const StaffRoleBadge({super.key, required this.role, this.isPending = false});

  final String role;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const KynzaBadge(
        label: 'EN ATTENTE',
        variant: KynzaBadgeVariant.warning,
      );
    }
    return KynzaBadge(
      label: role == 'manager' ? 'MANAGER' : 'STAFF',
      variant: role == 'manager'
          ? KynzaBadgeVariant.gold
          : KynzaBadgeVariant.neutral,
    );
  }
}
