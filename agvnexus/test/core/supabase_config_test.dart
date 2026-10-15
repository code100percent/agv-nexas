import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/core/config/app_config.dart';
import 'package:agvnexus/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig & AppConfig Safe Initialization Tests (Phase 2)', () {
    test(
      'Empty credentials gracefully bypasses Supabase initialization without throwing',
      () async {
        const config = AppConfig(supabaseUrl: '', supabaseAnonKey: '');

        expect(config.hasSupabaseConfig, isFalse);
        expect(
          config.connectionTierDescription,
          contains('Phase 1: Deterministic Simulation'),
        );

        await SupabaseConfig.initialize(config);
        expect(SupabaseConfig.isInitialized, isFalse);
        expect(SupabaseConfig.client, isNull);
      },
    );

    test(
      'Provides correct Phase 2 connection tier description when configured',
      () {
        const config = AppConfig(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'sample-anon-key-123',
        );

        expect(config.hasSupabaseConfig, isTrue);
        expect(
          config.connectionTierDescription,
          contains('Phase 2: Supabase PostgreSQL Persistence'),
        );
      },
    );
  });
}
