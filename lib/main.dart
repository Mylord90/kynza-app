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
import 'core/permissions/permission_cache.dart';
import 'core/security/certificate_pinning_service.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/hive_encryption_key_service.dart';
import 'core/services/legal_acceptance_queue_service.dart';
import 'core/services/mutation_outbox_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_monitoring_service.dart';
import 'core/services/secure_local_storage.dart';
import 'core/services/session_service.dart';
import 'core/services/timezone_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/profile_read_cache.dart';
import 'core/widgets/auth_boot_gate.dart';
import 'features/booking/data/booking_read_cache.dart';
import 'features/evolution/cms/data/cms_cache.dart';
import 'features/evolution/feature_flags/data/feature_flag_cache.dart';
import 'features/evolution/remote_config/data/remote_config_cache.dart';
import 'features/maps/data/salon_location_cache.dart';
import 'features/notifications/data/notification_read_cache.dart';
import 'features/search/data/search_read_cache.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/loader/providers/loader_overlay_provider.dart';
import 'shared/widgets/loader/widgets/loader_overlay.dart';

Future<void> main() async {
  runZonedGuarded(_bootstrap, (error, stack) {
    CrashReportingService.recordError(error, stack);
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  TimeZoneService.init();

  await Hive.initFlutter();
  final prefsCipher = await HiveEncryptionKeyService.getCipher();
  try {
    await Hive.openBox(SessionService.boxName, encryptionCipher: prefsCipher);
  } catch (_) {
    // An existing install's box was written before encryption was added
    // (plaintext) and can't be decrypted with the new cipher. This box only
    // ever holds a UI-preference cache (onboarding flag, language,
    // pending invitation/referral tokens, recent searches) — never the
    // source of truth, which lives in Supabase — so resetting it on the
    // one device that hits this is an acceptable, non-destructive-to-data
    // degrade, not a silent swallow of something important.
    await Hive.deleteBoxFromDisk(SessionService.boxName);
    await Hive.openBox(SessionService.boxName, encryptionCipher: prefsCipher);
  }
  await Hive.openBox(PermissionCache.boxName);
  await Hive.openBox(LegalAcceptanceQueueService.boxName);
  await Hive.openBox(LegalAcceptanceQueueService.deadLetterBoxName);
  await Hive.openBox(MutationOutboxService.boxName);
  await Hive.openBox(MutationOutboxService.deadLetterBoxName);
  await Hive.openBox(SalonLocationCache.boxName);
  await Hive.openBox(FeatureFlagCache.boxName);
  await Hive.openBox(RemoteConfigCache.boxName);
  await Hive.openBox(CmsCache.boxName);
  await Hive.openBox(SearchReadCache.boxName);
  // Cold-start-offline read caches (Master Plan CP3) hold real customer
  // PII (booking/client/notification details) — encrypted with the same
  // cipher as SessionService, same reasoning as that box.
  await Hive.openBox(
    BookingReadCache.boxName,
    encryptionCipher: prefsCipher,
  );
  await Hive.openBox(
    ProfileReadCache.boxName,
    encryptionCipher: prefsCipher,
  );
  await Hive.openBox(
    NotificationReadCache.boxName,
    encryptionCipher: prefsCipher,
  );
  await initializeDateFormatting('fr_FR');

  await Firebase.initializeApp();
  await CrashReportingService.init();
  await PerformanceMonitoringService.startColdStartTrace();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  assert(
    Env.supabaseUrl.startsWith('https://'),
    'SUPABASE_URL must be HTTPS — got: ${Env.supabaseUrl}',
  );

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    httpClient: CertificatePinningService.createClient(),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
      localStorage: SecureLocalStorage(),
    ),
  );

  runApp(const ProviderScope(child: KynzaApp()));
}

class KynzaApp extends ConsumerWidget {
  const KynzaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(currentLocaleProvider);
    final showLoaderOverlay = ref.watch(loaderOverlayProvider);
    return AuthBootGate(
      child: MaterialApp.router(
        title: KynzaConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (deviceLocale, supported) {
          if (deviceLocale == null) return const Locale('fr');
          for (final s in supported) {
            if (s.languageCode == deviceLocale.languageCode) return s;
          }
          return const Locale('fr');
        },
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              if (showLoaderOverlay) const KynzaLoaderOverlay(),
            ],
          );
        },
      ),
    );
  }
}
