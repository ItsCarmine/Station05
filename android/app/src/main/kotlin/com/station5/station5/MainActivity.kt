package com.station5.station5

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.Context
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.station5.station5/deepfocus"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "enableLockTask" -> {
                    // Start lock task mode (screen pinning)
                    try {
                        startLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("LOCK_TASK_ERROR", "Failed to enable lock task mode", e.toString())
                    }
                }
                "disableLockTask" -> {
                    // End lock task mode
                    try {
                        stopLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("LOCK_TASK_ERROR", "Failed to disable lock task mode", e.toString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
