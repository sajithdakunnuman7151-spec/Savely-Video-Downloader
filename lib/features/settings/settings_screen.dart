// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/theme_provider.dart';
import '../../core/native_bridge.dart';
// මේක හරියටම එකම ෆෝල්ඩරේ තියෙන නිසා මෙහෙම import කරන්නේ
import 'download_location.dart'; 

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark ||
        (currentTheme == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final currentDownloadLocation = ref.watch(downloadLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Preferences'),
          _buildDarkModeToggle(ref, isDarkMode),
          _buildDivider(),
          _buildFloatingButtonToggle(context),
          _buildDivider(),
          const SizedBox(height: 20),

          _buildSectionTitle('Downloads'),
          _buildDownloadLocationTile(context, ref, currentDownloadLocation),
          _buildDivider(),
          const SizedBox(height: 20),

          _buildSectionTitle('About App'),
          _buildVersionTile(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Colors.black12);
  }

  Widget _buildDarkModeToggle(WidgetRef ref, bool isDarkMode) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.redAccent),
      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Toggle between light and dark themes', style: TextStyle(color: Colors.grey)),
      activeThumbColor: Colors.redAccent, // activeColor වෙනුවට activeThumbColor
      value: isDarkMode,
      onChanged: (bool value) {
        ref.read(themeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
      },
    );
  }

  Widget _buildFloatingButtonToggle(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.picture_in_picture, color: Colors.redAccent),
      title: const Text('Floating Download Button', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Show download button over TikTok & YouTube', style: TextStyle(color: Colors.grey)),
      activeThumbColor: Colors.redAccent, // activeColor වෙනුවට activeThumbColor
      value: false, 
      onChanged: (bool value) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Floating Download Button එක වැඩ කරන්නේ Android වල පමණි!'),
              backgroundColor: Colors.blue,
            ),
          );
          return;
        }

        if (value) {
          NativeBridge.requestPermissions();
          NativeBridge.toggleOverlayService(true);
        } else {
          NativeBridge.toggleOverlayService(false);
        }
      },
    );
  }

  Widget _buildDownloadLocationTile(BuildContext context, WidgetRef ref, String currentPath) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_outlined, color: Colors.redAccent),
      title: const Text('Download Location', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(currentPath, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: () async {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot change folders on Web preview.')),
          );
          return;
        }

        // FilePicker එකේ අලුත් ක්‍රමය
        String? selectedDirectory = await FilePicker.getDirectoryPath();
        
        // Context එක තවමත් තියෙනවද කියලා බලනවා (use_build_context_synchronously Error එකට විසඳුම)
        if (!context.mounted) return;

        if (selectedDirectory != null) {
          ref.read(downloadLocationProvider.notifier).setLocation(selectedDirectory);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download location saved to: $selectedDirectory'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Widget _buildVersionTile() {
    return const ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.info_outline, color: Colors.redAccent),
      title: Text('Version', style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }
}