import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../router/app_router.dart';
import '../../features/auth/domain/states/auth_ui_state.dart';
import '../../shared/widgets/kynza_notification_banner.dart';
import '../../shared/widgets/kynza_skeleton.dart';

/// Blocks rendering of the router until the very first auth/session check
/// resolves, so no screen ever watches an uninitialized auth state.
class AuthBootGate extends ConsumerWidget {
  const AuthBootGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.valueOrNull is AuthAuthenticated;
      final isAuthenticated = next.valueOrNull is AuthAuthenticated;
      if (isAuthenticated && !wasAuthenticated) {
        final service = ref.read(notificationServiceProvider);
        service.initialize();
        service.onForegroundMessage = (message) {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx == null) return;
          showKynzaNotificationBanner(
            ctx,
            title: message.notification?.title ?? 'KYNZA',
            subtitle: message.notification?.body ?? '',
            onTap: () {
              final deepLink = message.data['deepLink'] as String?;
              if (deepLink != null) ctx.go(deepLink);
            },
          );
        };
        service.tapHandler = (message) {
          final deepLink = message.data['deepLink'] as String?;
          final ctx = rootNavigatorKey.currentContext;
          if (deepLink != null && ctx != null) ctx.go(deepLink);
        };
      }
    });

    final auth = ref.watch(authNotifierProvider);
    return auth.when(
      loading: () => const _SplashLoader(),
      error: (_, __) => child,
      data: (_) => child,
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.md_,
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const KynzaSkeleton(width: 120, height: 6, radius: 3),
            ],
          ),
        ),
      ),
    );
  }
}
