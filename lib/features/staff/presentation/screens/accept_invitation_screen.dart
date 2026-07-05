import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../auth/application/providers/auth_notifier_provider.dart';

enum _InvitationStatus { verifying, success, error }

/// Reached either directly via the com.kynza.app://accept-invitation deep
/// link (existing, logged-in staff) or via SessionService's pending-token
/// detour through register/complete-profile (brand-new staff with no
/// account yet) — see resolvePostAuthRoute in auth_redirect.dart.
class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends ConsumerState<AcceptInvitationScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spring,
  );
  _InvitationStatus _status = _InvitationStatus.verifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      _fail();
      return;
    }

    if (SupabaseService.auth.currentSession == null) {
      // No account yet (or logged out) — stash the token and detour
      // through registration; resolvePostAuthRoute brings the user back
      // here once they have a session.
      await ref.read(sessionServiceProvider).savePendingInvitationToken(token);
      if (!mounted) return;
      context.go(RouteNames.register);
      return;
    }

    try {
      final res = await SupabaseService.client.functions.invoke(
        'accept-invitation',
        body: {'invitation_token': token},
      );
      final data = res.data is Map ? res.data as Map : null;
      if (res.status != 200 || data?['success'] != true) {
        _fail();
        return;
      }

      await SupabaseService.auth.refreshSession();
      ref.invalidate(currentUserProfileProvider);
      await ref.read(authNotifierProvider.notifier).refreshProfile();

      if (!mounted) return;
      setState(() => _status = _InvitationStatus.success);
      _controller.forward();
      await Future.delayed(AppDurations.shimmer);
      if (!mounted) return;
      context.go(RouteNames.homeStaff);
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _status = _InvitationStatus.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (_status) {
        _InvitationStatus.verifying => KynzaLoaderOverlay(
          message: context.l10n.staffAcceptInvitationVerifying,
        ),
        _InvitationStatus.error => KynzaErrorState(
          message: context.l10n.acceptInvitationError,
          onRetry: () => context.go(RouteNames.login),
        ),
        _InvitationStatus.success => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 96,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.acceptInvitationWelcome,
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      },
    );
  }
}
