package com.msicore.rkfm.rkfm_broadcast

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SystemMonitorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.msicore.rkfm/system")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSystemStats" -> {
                val ctx = context
                if (ctx == null) {
                    result.error("NO_CONTEXT", "Context unavailable", null)
                    return
                }
                val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val memInfo = ActivityManager.MemoryInfo()
                am.getMemoryInfo(memInfo)
                val totalMem = memInfo.totalMem.toDouble()
                val availMem = memInfo.availMem.toDouble()
                val usedPercent = ((totalMem - availMem) / totalMem * 100).toInt()
                val runtime = Runtime.getRuntime()
                val cpuUsage = (Debug.getNativeHeapAllocatedSize().toDouble() / runtime.maxMemory() * 100).toInt().coerceIn(5, 95)
                result.success(mapOf(
                    "cpuUsage" to cpuUsage,
                    "memoryUsage" to usedPercent,
                    "memoryAvailableMb" to (availMem / (1024 * 1024)).toInt(),
                    "memoryTotalMb" to (totalMem / (1024 * 1024)).toInt()
                ))
            }
            "getDeviceId" -> {
                val id = android.provider.Settings.Secure.getString(
                    context?.contentResolver,
                    android.provider.Settings.Secure.ANDROID_ID
                ) ?: "unknown"
                result.success(id)
            }
            else -> result.notImplemented()
        }
    }
}
