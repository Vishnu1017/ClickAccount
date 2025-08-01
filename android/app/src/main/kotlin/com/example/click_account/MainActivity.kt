package com.example.click_account

import android.content.Intent
import android.os.Bundle
import android.os.Process
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Add this crash handler block
        Thread.setDefaultUncaughtExceptionHandler { thread, ex ->
            Log.e("CRASH", "Native crash occurred", ex)
            
            // If you have Firebase Crashlytics, uncomment:
            // FirebaseCrashlytics.getInstance().recordException(ex)
            
            // Restart app
            val restartIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            startActivity(restartIntent)
            finish()
            Process.killProcess(Process.myPid())
            System.exit(1)
        }
        
        super.onCreate(savedInstanceState)
    }
}