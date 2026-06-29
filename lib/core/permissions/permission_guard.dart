import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permission_service.dart';

/// Hides [child] until the current user is known to hold
/// (feature, action, resource). Renders [fallback] (or nothing) while
/// loading/denied/erroring — never flashes the gated content first.
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    super.key,
    required this.feature,
    required this.action,
    this.resource = '',
    required this.child,
    this.fallback,
  });

  final String feature;
  final String action;
  final String resource;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (feature: feature, action: action, resource: resource);
    final hasPermAsync = ref.watch(permissionProvider(query));
    return hasPermAsync.when(
      data: (hasPerm) =>
          hasPerm ? child : (fallback ?? const SizedBox.shrink()),
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}
