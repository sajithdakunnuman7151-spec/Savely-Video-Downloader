// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme_provider.dart';
import '../../core/native_bridge.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // දැනට තියෙන Theme එක මොකක්ද කියලා බලනවා
    final currentTheme = ref.watch(themeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark || 
        (currentTheme == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Preferences',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),
        
        // 1. Theme Toggle එක
        SwitchListTile(
          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Toggle between light and dark themes'),
          secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.red),
          activeThumbColor: Colors.red,
          value: isDarkMode,
          onChanged: (value) {
            // Switch එක එබුවම Theme එක වෙනස් කරනවා
            ref.read(themeProvider.notifier).state = 
                value ? ThemeMode.dark : ThemeMode.light;
          },
        ),

        const Divider(),
        
        // අලුත් Floating Button Switch එක
        SwitchListTile(
          title: const Text('Floating Download Button', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Show download button over TikTok & YouTube'),
          secondary: const Icon(Icons.picture_in_picture, color: Colors.red),
          activeThumbColor: Colors.red,
          value: false, // පසුව මේකත් Riverpod එකෙන් manage කරමු
          onChanged: (value) {
            if (value) {
              // On කරද්දී Android පැත්තෙන් Permission ඉල්ලනවා
              NativeBridge.requestPermissions();
              NativeBridge.toggleOverlayService(true);
            } else {
              NativeBridge.toggleOverlayService(false);
            }
          },
        ),
        
        
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Downloads',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),

        // 2. Download Location එක පෙන්වන තැන
        ListTile(
          leading: const Icon(Icons.folder_outlined, color: Colors.red),
          title: const Text('Download Location', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('/storage/emulated/0/Download'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom locations coming soon!')),
            );
          },
        ),

        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'About App',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),

        // 3. App Version එක
        const ListTile(
          leading: Icon(Icons.info_outline, color: Colors.red),
          title: Text('Version', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      ],
    );
  }
}