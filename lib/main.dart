// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/app_theme.dart';
import 'core/theme_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  // මේක අනිවාර්යයෙන්ම තියෙන්න ඕනේ
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 Web එකක් "නොවේ" නම් පමණක් (Android/iOS නම් පමණක්) ක්‍රියාත්මක වන කොටස
  if (!kIsWeb) {
    // අනාගතයේදී ඔයා AdMob හරි, Android වලට විතරක් තියෙන දේවල් හරි දානවා නම්,
    // ඒ දේවල් මෙතන initialize කරන්න පුළුවන්. 
    // උදාහරණ: MobileAds.instance.initialize();
  }

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
      themeMode: themeMode, 
      home: const HomeScreen(),
    );
  }
}