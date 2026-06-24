// lib/core/native_bridge.dart
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeBridge {
  // මේ නම අනිවාර්යයෙන්ම Kotlin පැත්තේ නමට සමාන වෙන්න ඕනේ
  static const MethodChannel _channel = MethodChannel('com.savely.app/overlay');

  /// Overlay සහ Accessibility Permissions ඉල්ලන්න Android පැත්තට පණිවිඩයක් යැවීම
  static Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      debugPrint("Failed to request permissions: '${e.message}'.");
    }
  }

  /// Floating Service එක On/Off කරන්න
  static Future<void> toggleOverlayService(bool start) async {
    try {
      if (start) {
        await _channel.invokeMethod('startService');
      } else {
        await _channel.invokeMethod('stopService');
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle service: '${e.message}'.");
    }
  }
}