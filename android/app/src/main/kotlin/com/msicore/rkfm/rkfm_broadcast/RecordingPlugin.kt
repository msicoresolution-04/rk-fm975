package com.msicore.rkfm.rkfm_broadcast

import android.content.Context
import android.os.Environment
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recording
import androidx.camera.video.VideoRecordEvent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicReference

class RecordingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var cameraPlugin: CameraXPlugin? = null
    private var appContext: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val activeRecording = AtomicReference<Recording?>(null)
    private var currentPath: String? = null

    fun setCameraPlugin(plugin: CameraXPlugin) {
        cameraPlugin = plugin
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.msicore.rkfm/recording")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopRecordingInternal()
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> {
                val programName = call.argument<String>("programName") ?: "broadcast"
                startRecording(programName, result)
            }
            "stopRecording" -> {
                stopRecordingInternal()
                result.success(mapOf("path" to currentPath, "success" to true))
            }
            "pauseRecording" -> {
                activeRecording.get()?.pause()
                result.success(true)
            }
            "resumeRecording" -> {
                activeRecording.get()?.resume()
                result.success(true)
            }
            "getStatus" -> result.success(mapOf(
                "recording" to (activeRecording.get() != null),
                "path" to currentPath
            ))
            else -> result.notImplemented()
        }
    }

    private fun startRecording(programName: String, result: MethodChannel.Result) {
        val videoCapture = cameraPlugin?.getVideoCapture()
        val context = activityBinding?.activity ?: appContext
        if (videoCapture == null || context == null) {
            result.error("NO_CAMERA", "Video capture not available", null)
            return
        }
        try {
            val now = java.time.LocalDateTime.now()
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES),
                "RKFM/Recordings/${now.year}/${now.monthValue}/${now.dayOfMonth}/$programName"
            )
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, "recording_${System.currentTimeMillis()}.mp4")
            currentPath = file.absolutePath

            val outputOptions = FileOutputOptions.Builder(file).build()
            val recording = videoCapture.output
                .prepareRecording(context, outputOptions)
                .start(ContextCompat.getMainExecutor(context)) { event ->
                    if (event is VideoRecordEvent.Finalize && !event.hasError()) {
                        currentPath = file.absolutePath
                    }
                }
            activeRecording.set(recording)
            result.success(mapOf("path" to file.absolutePath))
        } catch (e: Exception) {
            result.error("RECORD_ERROR", e.message, null)
        }
    }

    private fun stopRecordingInternal() {
        activeRecording.getAndSet(null)?.stop()
    }
}
