import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/env.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    const ProviderScope(
      child: KynzaApp(),
    ),
  );
}

class KynzaApp extends StatelessWidget {
  const KynzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KYNZA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Text(
            'KYNZA',
            style: TextStyle(
              color: Color(0xFFEAB308),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
        ),
      ),
    );
  }
}
