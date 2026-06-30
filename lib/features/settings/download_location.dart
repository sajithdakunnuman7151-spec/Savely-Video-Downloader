// lib/features/settings/download_location.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================
// DOWNLOAD LOCATION NOTIFIER
// ඩවුන්ලෝඩ් කරන ෆෝල්ඩර් එක මතක තියාගන්න සහ වෙනස් කරන්න
// =========================================================
class DownloadLocationNotifier extends StateNotifier<String> {
  
  // ආරම්භයේදී හිස් අගයක් ලබා දේ (පසුව _initLocation හරහා සකස් වේ)
  DownloadLocationNotifier() : super('') {
    _initLocation(); 
  }

  // --- 1. ස්ථානය (Location) ආරම්භ කිරීම ---
  Future<void> _initLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('custom_download_location');
    
    if (savedLocation != null) {
      // කලින් සේව් කරපු එකක් තියෙනවා නම් ඒක ගන්නවා
      state = savedLocation;
    } else {
      // නැත්නම් Android වල සාමාන්‍ය Download ෆෝල්ඩරය ලබා දෙනවා
      if (Platform.isAndroid) {
        state = '/storage/emulated/0/Download/Savely';
      } else {
        state = ''; // iOS හෝ වෙබ් සඳහා පසුව සකස් කළ හැක
      }
    }
  }

  // --- 2. අලුත් ස්ථානයක් (Location) සේව් කිරීම ---
  Future<void> setLocation(String newLocation) async {
    state = newLocation; // UI එකට අලුත් Location එක දෙනවා
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_download_location', newLocation); // ෆෝන් එකේ සේව් කරනවා
  }
}

// =========================================================
// PROVIDER EXPORT
// =========================================================
final downloadLocationProvider = StateNotifierProvider<DownloadLocationNotifier, String>((ref) {
  return DownloadLocationNotifier();
});