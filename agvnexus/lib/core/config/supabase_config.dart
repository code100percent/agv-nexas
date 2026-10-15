import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

/// Centralized configuration and initialization wrapper for Supabase services.
class SupabaseConfig {
  static bool _isInitialized = false;

  /// Returns true if Supabase SDK was successfully initialized with valid endpoints.
  static bool get isInitialized => _isInitialized;

  /// Initialize the Supabase Flutter client.
  /// If credentials are not supplied (e.g. offline simulation or unit tests),
  /// initialization is bypassed gracefully without raising an unhandled exception.
  static Future<void> initialize(AppConfig config) async {
    if (!config.hasSupabaseConfig) {
      debugPrint(
        '[SupabaseConfig] No Supabase credentials provided; running in deterministic offline/simulation mode.',
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('[SupabaseConfig] Supabase successfully initialized.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[SupabaseConfig] Supabase initialization failed: $e');
    }
  }

  /// Safe accessor for the SupabaseClient instance.
  /// Returns null if Supabase is not active.
  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
