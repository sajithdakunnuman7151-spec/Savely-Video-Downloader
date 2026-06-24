// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'core/theme_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ProviderScope එකෙන් මුළු app එකම wrap කරලා තියෙන්නේ
  runApp(const ProviderScope(child: SavelyApp()));
}

class SavelyApp extends ConsumerWidget {
  const SavelyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme එක වෙනස් වෙනකොට මෙතනින් අල්ලගන්නවා
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Savely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // මෙතනට අලුත් Theme එක දෙනවා
      home: const HomeScreen(),
    );
  }
}