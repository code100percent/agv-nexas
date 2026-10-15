/// AGV Nexus Application Configuration
/// Provides environment variables, runtime flags, and connectivity configurations.
class AppConfig {
  final String appName;
  final String appVersion;
  final String environment;
  final bool isSimulatedMode;
  final String apiBaseUrl;
  final String wsBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig({
    this.appName = 'AGV Nexus',
    this.appVersion = '1.0.0-phase6',
    this.environment = const String.fromEnvironment(

      'ENV',
      defaultValue: 'development',
    ),
    this.isSimulatedMode = const bool.fromEnvironment(
      'SIMULATED_MODE',
      defaultValue: true,
    ),
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1',
    ),
    this.wsBaseUrl = const String.fromEnvironment(
      'WS_BASE_URL',
      defaultValue: 'ws://localhost:8000/ws/telemetry',
    ),
    this.supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: String.fromEnvironment(
        'NEXT_PUBLIC_SUPABASE_URL',
        defaultValue: 'https://bphxvupyupfbzmdrcnqs.supabase.co',
      ),
    ),
    this.supabaseAnonKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: String.fromEnvironment(
          'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
          defaultValue: 'sb_publishable_V4W0iPAjRfqQe4pJygifnw_pXPGNk0b',
        ),
      ),
    ),
  });

  bool get isProduction => environment == 'production';
  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Human-readable indicator of the current integration tier.
  String get connectionTierDescription {
    if (hasSupabaseConfig) {
      return 'Phase 2: Supabase PostgreSQL Persistence & Auth ($supabaseUrl)';
    }
    if (isSimulatedMode) {
      return 'Phase 1: Deterministic Simulation / Mock Repository';
    }
    return 'Live Robotics Gateway ($apiBaseUrl)';
  }
}
