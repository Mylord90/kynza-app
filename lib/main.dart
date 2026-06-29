import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/env.dart';
import 'core/constants/kynza_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_service.dart';
import 'core/services/timezone_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_boot_gate.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  runZonedGuarded(_bootstrap, (error, stack) {
    CrashReportingService.recordError(error, stack);
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  TimeZoneService.init();

  await Hive.initFlutter();
  await Hive.openBox(SessionService.boxName);
  await initializeDateFormatting('fr_FR');

  await Firebase.initializeApp();
  await CrashReportingService.init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );

  runApp(const ProviderScope(child: KynzaApp()));
}

class KynzaApp extends ConsumerWidget {
  const KynzaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final language = ref.watch(languageProvider);
    return AuthBootGate(
      child: MaterialApp.router(
        title: KynzaConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
