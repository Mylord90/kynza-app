// KYNZA — Configuration d'environnement
// Les valeurs sont chargées depuis --dart-define au build

abstract class Env {
  // Supabase
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // App
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDev => appEnv == 'development';
  static bool get isProd => appEnv == 'production';

  // Google Maps (Phase 7 scaffold — inert until a real key is supplied and
  // explicitly confirmed; see docs/GOOGLE_MAPS_ARCHITECTURE.md). Empty by
  // default on purpose — no key is committed anywhere, and every Maps
  // repository treats an empty key the same as the feature flag being off.
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // App Check / Play Integrity (Phase 10 scaffold — inert until explicitly
  // set to true AND a real Firebase App Check provider has been activated
  // in the Play/Firebase consoles; see docs/security/APP_CHECK_ARCHITECTURE.md).
  // False by default on purpose — same double-gate shape as Google Maps
  // above (an env-level switch AND a feature-flag evaluation, both must
  // hold).
  static const appCheckEnabled = bool.fromEnvironment(
    'APP_CHECK_ENABLED',
    defaultValue: false,
  );
}
