import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig();
  await SupabaseConfig.initialize(config);
  runApp(
    const ProviderScope(
      child: AgvNexusApp(),
    ),
  );
}
