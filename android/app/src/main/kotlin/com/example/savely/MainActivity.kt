package com.savely.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Flutter පැත්තේ තියෙන නමටම මේක සමාන වෙන්න ඕනේ
    private val CHANNEL = "com.savely.app/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // 1. Permission එක ඉල්ලන පණිවිඩය ආවම
                "requestPermissions" -> {
                    checkOverlayPermission()
                    result.success(null)
                }
                // 2. Service එක On කරන්න කිව්වම
                "startService" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                    } else {
                        startService(Intent(this, FloatingService::class.java))
                        result.success(true)
                    }
                }
                // 3. Service එක Off කරන්න කිව්වම
                "stopService" -> {
                    stopService(Intent(this, FloatingService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // තිරය උඩින් පෙන්වන්න (Draw over other apps) අවසර ගන්නා කෝඩ් එක
    private fun checkOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                startActivityForResult(intent, 1000)
            }
        }
    }
}