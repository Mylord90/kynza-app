import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/connectivity_service.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
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
}

final confidentialModeProvider =
    NotifierProvider<ConfidentialModeNotifier, bool>(
      ConfidentialModeNotifier.new,
    );

/// App locale code. Defaults to French (fr_BI market). Persisted in Hive.
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    listenSelf(
      (previous, next) => ref.read(sessionServiceProvider).saveLanguage(next),
    );
    return ref.watch(sessionServiceProvider).getLanguage();
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);
