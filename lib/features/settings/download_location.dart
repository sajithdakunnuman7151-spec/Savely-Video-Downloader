
// lib/features/settings/download_location.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'download_location_unsupported.dart' 
    if (dart.library.io) 'download_location_mobile.dart';

// =========================================================
// DOWNLOAD LOCATION NOTIFIER
// =========================================================
class DownloadLocationNotifier extends StateNotifier<String> {
  
  DownloadLocationNotifier() : super('') {
    _initLocation(); 
  }

  Future<void> _initLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('custom_download_location');
    
    if (savedLocation != null) {
      state = savedLocation;
    } else {
      state = getInitialDownloadLocation();
    }
  }

  Future<void> setLocation(String newLocation) async {
    state = newLocation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_download_location', newLocation);
  }
}

// =========================================================
// PROVIDER EXPORT
// =========================================================
final downloadLocationProvider = StateNotifierProvider<DownloadLocationNotifier, String>((ref) {
  return DownloadLocationNotifier();
});
