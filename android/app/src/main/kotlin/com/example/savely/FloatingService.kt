package com.savely.app 

import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast

class FloatingService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var floatingButton: ImageView

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // පාවෙන බොත්තමේ පෙනුම හදනවා (දැනට රතු පාට රවුමක්)
        floatingButton = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_save) // Save Icon එක
            setBackgroundColor(Color.parseColor("#E53935")) // රතු පාට
            setPadding(30, 30, 30, 30)
        }

        // Android Version එක අනුව Overlay ජාතිය තෝරනවා
        val layoutFlag: Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 300 // උඩ ඉඳන් කොච්චර පල්ලෙහායින්ද තියෙන්නේ කියලා
        }

        windowManager.addView(floatingButton, params)

        // බොත්තම ඔබද්දී සහ එහෙමෙහෙ ගෙනියද්දී වෙන දේ (Drag & Click)
        floatingButton.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                when (event?.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        val xDiff = (event.rawX - initialTouchX).toInt()
                        val yDiff = (event.rawY - initialTouchY).toInt()
                        
                        // බොත්තම එහෙමෙහෙ ගෙනිච්චේ නැත්නම්, ඒක Click එකක් විදිහට සලකනවා
                        if (xDiff < 10 && yDiff < 10) {
                            Toast.makeText(applicationContext, "Opening Savely...", Toast.LENGTH_SHORT).show()
                            
                            // අපේ App එක ඕපන් කරනවා
                            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                        }
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        // ඇඟිල්ලෙන් අදිනකොට බොත්තමත් ඒ එක්කම යනවා
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(floatingButton, params)
                        return true
                    }
                }
                return false
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        // Service එක නවත්තද්දී බොත්තම අයින් කරනවා
        if (::floatingButton.isInitialized) {
            windowManager.removeView(floatingButton)
        }
    }
}