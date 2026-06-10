import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaan_app/screens/intro_screen.dart';
import 'package:amaan_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kcaevbybsqokbteunsmg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjYWV2Ynlic3Fva2J0ZXVuc21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NzE1MjAsImV4cCI6MjA5MjM0NzUyMH0.c0Jm7o6Ekekdxy-IYI-1HWeNpl8DfbiQFgGXrAdPeuk',
  );

  runApp(const AmaanApp());
}

class AmaanApp extends StatelessWidget {
  const AmaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session != null
          ? const HomeScreen() // ✅ already logged in
          : const IntroScreen(), // ❌ not logged in
    );
  }
}
