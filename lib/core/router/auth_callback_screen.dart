import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/datasources/auth_supabase_datasource.dart';
import '../../shared/widgets/kynza_loading_overlay.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';
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
      if (!mounted) return;
      context.go(redirectAfterAuth(profile));
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
      body: KynzaLoadingOverlay(message: 'Connexion en cours...'),
    );
  }
}

class AuthCallbackError implements Exception {
  const AuthCallbackError(this.code);
  final String code;

  @override
  String toString() => code;
}
