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
}
