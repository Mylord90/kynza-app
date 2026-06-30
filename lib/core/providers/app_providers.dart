import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/models/language_enum.dart';
import '../localization/services/locale_detection_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Owner-only toggle that masks every amount on screen. Persisted in Hive.
class ConfidentialModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    listenSelf(
      (previous, next) =>
          ref.read(sessionServiceProvider).saveConfidentialMode(next),
    );
    return ref.watch(sessionServiceProvider).getConfidentialMode();
  }

  void toggle() => state = !state;
}

final confidentialModeProvider =
    NotifierProvider<ConfidentialModeNotifier, bool>(
      ConfidentialModeNotifier.new,
    );

/// App locale code ('fr' or 'en'). Persisted in Hive.
/// On first run with no stored preference, detects the system language automatically.
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final session = ref.watch(sessionServiceProvider);
    final stored = session.getLanguage();

    // If the user has never explicitly set a language, detect from system locale
    if (!session.hasStoredLanguage()) {
      final detected = const LocaleDetectionService().detectSystemLanguage();
      final detectedCode = detected.code;
      // Persist so next build() uses the stored value
      Future.microtask(() => session.saveLanguage(detectedCode));
      listenSelf((_, next) => session.saveLanguage(next));
      return detectedCode;
    }

    listenSelf((_, next) => session.saveLanguage(next));
    return stored;
  }

  void setLanguage(String code) {
    state = code;
    // Sync to Supabase in background (non-blocking, never throws to UI)
    _syncToServer(code);
  }

  Future<void> _syncToServer(String code) async {
    final user = SupabaseService.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.from(
        'users',
      ).update({'preferred_language': code}).eq('id', user.id);
    } catch (_) {
      // Sync failure never blocks the local change
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

/// Computed Locale from the active language code — use this in MaterialApp.
final currentLocaleProvider = Provider<Locale>((ref) {
  return Locale(ref.watch(languageProvider));
});

/// Typed AppLanguage from the active language code.
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return AppLanguage.fromCodeOrFallback(ref.watch(languageProvider));
});
