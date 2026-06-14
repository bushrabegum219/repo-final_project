import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaan_app/screens/intro_screen.dart';
import 'package:amaan_app/constants/app_theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kcaevbybsqokbteunsmg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjYWV2Ynlic3Fva2J0ZXVuc21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NzE1MjAsImV4cCI6MjA5MjM0NzUyMH0.c0Jm7o6Ekekdxy-IYI-1HWeNpl8DfbiQFgGXrAdPeuk',
  );

  await _loadSavedTheme();

  runApp(const AmaanApp());
}

Future<void> _loadSavedTheme() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  try {
    final data = await supabase
        .from('user_settings')
        .select('dark_mode_on')
        .eq('user_id', user.id)
        .maybeSingle();

    AppThemeController.isDarkMode.value = data?['dark_mode_on'] == true;
  } catch (e) {
    debugPrint("THEME LOAD ERROR: $e");
  }
}

class AmaanApp extends StatelessWidget {
  const AmaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppThemeController.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F6FB),
            primaryColor: const Color(0xFF9B75F0),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9B75F0),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF9B75F0),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9B75F0),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const IntroScreen(),
        );
      },
    );
  }
}