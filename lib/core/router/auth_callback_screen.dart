import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers/auth_notifier_provider.dart';
import '../../features/auth/data/datasources/auth_supabase_datasource.dart';
import '../../shared/widgets/loader/widgets/loader_overlay.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../services/supabase_service.dart';
import '../utils/auth_errors.dart';
import '../utils/auth_redirect.dart';
import 'route_names.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    final code = GoRouterState.of(context).uri.queryParameters['code'];
    try {
      if (code != null && code.isNotEmpty) {
        await SupabaseService.auth.exchangeCodeForSession(code);
      }

      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) throw const AuthCallbackError('no_session');

      final profile = await _fetchOrCreateProfile(userId);
      // Without this, authNotifierProvider's cache still says
      // "unauthenticated" and the router's redirect guard bounces the
      // very next navigation straight back to /auth/login. Also
      // invalidate currentUserProfileProvider itself — refreshProfile()
      // only updates authNotifierProvider's own cache, and other
      // screens (e.g. ownerSalonProvider) read the separate
      // currentUserProfileProvider, which would otherwise keep serving
      // whichever account was cached before this OAuth sign-in.
      ref.invalidate(currentUserProfileProvider);
      await ref.read(authNotifierProvider.notifier).refreshProfile();
      if (!mounted) return;
      final route = await resolvePostAuthRoute(
        ref.read(sessionServiceProvider),
        profile,
      );
      if (!mounted) return;
      context.go(route);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e))));
      context.go(RouteNames.login);
    }
  }

  Future<UserProfile> _fetchOrCreateProfile(String userId) async {
    try {
      return await AuthSupabaseDatasource().fetchProfileWithRetry(userId);
    } catch (_) {
      final user = SupabaseService.auth.currentUser!;
      await SupabaseService.from('users').insert({
        'id': userId,
        'email': user.email,
        'full_name': (user.userMetadata?['full_name'] as String?) ?? '',
        'auth_provider': user.appMetadata['provider'] ?? 'email',
        'email_verified': user.emailConfirmedAt != null,
      });
      final row = await SupabaseService.from(
        'users',
      ).select().eq('id', userId).single();
      return UserProfile.fromSupabase(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: KynzaLoaderOverlay(message: 'Connexion en cours...'),
    );
  }
}

class AuthCallbackError implements Exception {
  const AuthCallbackError(this.code);
  final String code;

  @override
  String toString() => code;
}
