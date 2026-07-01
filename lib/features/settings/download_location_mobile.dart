
// lib/features/settings/download_location_mobile.dart
import 'dart:io';

String getInitialDownloadLocation() {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/Download/Savely';
  } else {
    return ''; // iOS or other mobile platforms
  }
}
