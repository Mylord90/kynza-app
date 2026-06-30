import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

enum _ClaimStatus { verifying, success, error }

/// Reached either directly via the com.kynza.app://accept-referral deep
/// link (existing, logged-in user) or via SessionService's pending-token
/// detour through register (brand-new user with no account yet) — see
/// resolvePostAuthRoute in auth_redirect.dart. Mirrors AcceptInvitationScreen.
class ReferralClaimScreen extends ConsumerStatefulWidget {
  const ReferralClaimScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ReferralClaimScreen> createState() =>
      _ReferralClaimScreenState();
}

class _ReferralClaimScreenState extends ConsumerState<ReferralClaimScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spring,
  );
  _ClaimStatus _status = _ClaimStatus.verifying;
  String _errorMessage = '';
  bool _stampGranted = false;
  String? _salonName;

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
      await ref.read(sessionServiceProvider).savePendingReferralToken(token);
      if (!mounted) return;
      context.go(RouteNames.register);
      return;
    }

    try {
      final res = await SupabaseService.client.functions.invoke(
        'claim-referral',
        body: {'referral_token': token},
      );
      final data = res.data is Map ? res.data as Map : null;
      if (res.status != 200 || data?['success'] != true) {
        _fail();
        return;
      }

      if (!mounted) return;
      setState(() {
        _status = _ClaimStatus.success;
        _stampGranted = data?['stampGranted'] == true;
        _salonName = data?['salonName'] as String?;
      });
      _controller.forward();
      await Future.delayed(AppDurations.shimmer);
      if (!mounted) return;
      context.go(RouteNames.homeClient);
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _status = _ClaimStatus.error;
      _errorMessage = context.l10n.referralInvalidLink;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (_status) {
        _ClaimStatus.verifying => KynzaLoadingOverlay(
          message: context.l10n.referralClaimVerifying,
        ),
        _ClaimStatus.error => KynzaErrorState(
          message: _errorMessage,
          onRetry: () => context.go(RouteNames.homeClient),
        ),
        _ClaimStatus.success => Center(
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
                  context.l10n.referralWelcomeTitle,
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                if (_stampGranted) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _salonName == null
                        ? context.l10n.referralStampGranted
                        : context.l10n.referralStampGrantedWithSalon(_salonName!),
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      },
    );
  }
}
